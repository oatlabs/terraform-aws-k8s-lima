locals {
  config = jsondecode(var.config)

  organization       = local.config["organization"]
  k8s_clusters       = local.config["k8s_clusters"]
  talos_version      = local.config["talos_version"]
  kubernetes_version = local.config["kubernetes_version"]

  names = { for name in keys(local.k8s_clusters) : name => {
    aws   = substr(uuidv5("oid", name), 0, 32)
    talos = name
  } }

  # `talos` not `aws`: the CCM matches this key against the Talos cluster name.
  ccm_discovery_tags = { for name, cluster in local.names : name => {
    "kubernetes.io/cluster/${cluster.talos}" = "owned"
  } }

  common_tags = {
    Organization = local.organization
    Provisioner  = "Terraform"
    Platform     = "OatLabs"
  }

  cluster_tags = { for name, cluster in local.names : name => merge(local.common_tags, {
    ClusterName = cluster.talos
  }) }
}

module "network" {
  source   = "./modules/network"
  for_each = local.k8s_clusters

  region             = each.value.region
  name               = local.names[each.key].aws
  vpc_cidr           = each.value.vpc_cidr
  subnets            = each.value.subnets
  tags               = local.cluster_tags[each.key]
  ccm_discovery_tags = local.ccm_discovery_tags[each.key]
}

module "ccm" {
  source   = "./modules/ccm"
  for_each = local.k8s_clusters

  name_prefix = local.names[each.key].aws
  tags        = local.cluster_tags[each.key]
}

module "ebs_csi" {
  source   = "./modules/ebs-csi"
  for_each = local.k8s_clusters

  name_prefix = local.names[each.key].aws
  tags        = local.cluster_tags[each.key]
}

module "nodes" {
  source   = "./modules/nodes"
  for_each = local.k8s_clusters

  region            = each.value.region
  name_prefix       = local.names[each.key].aws
  public_subnet_ids = module.network[each.key].public_subnet_ids
  security_group_id = module.network[each.key].cluster_security_group_id
  talos_version     = local.talos_version
  iam_role_policies = {
    for role in keys(module.ccm[each.key].iam_role_policies) : role => merge(
      module.ccm[each.key].iam_role_policies[role],
      module.ebs_csi[each.key].iam_role_policies[role],
    )
  }
  k8s_control_plane  = each.value.k8s_control_plane
  k8s_workers        = each.value.k8s_workers
  ccm_discovery_tags = local.ccm_discovery_tags[each.key]
  extra_tags         = local.cluster_tags[each.key]
}

resource "aws_elb" "k8s_elb" {
  for_each = local.k8s_clusters

  region  = each.value.region
  name    = local.names[each.key].aws
  subnets = values(module.network[each.key].public_subnet_ids)
  tags    = merge(local.cluster_tags[each.key], local.ccm_discovery_tags[each.key])
  security_groups = [
    module.network[each.key].cluster_security_group_id,
    module.network[each.key].kubernetes_api_security_group_id,
  ]

  cross_zone_load_balancing = true
  idle_timeout              = 600

  listener {
    lb_port           = 443
    lb_protocol       = "tcp"
    instance_port     = 6443
    instance_protocol = "tcp"
  }

  health_check {
    target              = "tcp:6443"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  instances = [for key in module.nodes[each.key].controlplane_keys : module.nodes[each.key].instances[key].id]
}

module "talos" {
  source   = "./modules/talos"
  for_each = local.k8s_clusters

  cluster_name           = local.names[each.key].talos
  cluster_endpoint       = aws_elb.k8s_elb[each.key].dns_name
  talos_version_contract = local.talos_version
  kubernetes_version     = local.kubernetes_version

  config_patches = concat(
    module.ccm[each.key].machine_config_patches,
    [yamlencode({
      cluster = {
        network = {
          cni = {
            name = "flannel"
            flannel = {
              kubeNetworkPoliciesEnabled = true
            }
          }
        }
      }
    })],
    [yamlencode({
      machine = {
        kubelet = {
          registerWithFQDN = true
        }
        install = {
          image = "ghcr.io/siderolabs/installer:${local.talos_version}"
        }
      }
    })],
  )

  node_config_patches = {
    for key, node in module.nodes[each.key].node_instances : key => [yamlencode({
      machine = merge(
        { nodeLabels = node.node_labels },
        length(node.registration_taints) > 0 ? {
          kubelet = { extraConfig = { registerWithTaints = node.registration_taints } }
        } : {},
      )
    })]
  }

  node_instances    = module.nodes[each.key].node_instances
  controlplane_keys = module.nodes[each.key].controlplane_keys
  worker_keys       = module.nodes[each.key].worker_keys
  instances         = module.nodes[each.key].instances
}

data "talos_cluster_health" "this" {
  for_each = local.k8s_clusters

  depends_on = [module.talos]

  client_configuration = module.talos[each.key].client_configuration
  endpoints            = [for key in module.nodes[each.key].controlplane_keys : module.nodes[each.key].instances[key].public_ip]
  control_plane_nodes  = [for key in module.nodes[each.key].controlplane_keys : module.nodes[each.key].instances[key].private_ip]
  worker_nodes         = [for key in module.nodes[each.key].worker_keys : module.nodes[each.key].instances[key].private_ip]
}

# Install CSI after the health check rather than at bootstrap
module "ebs_csi_driver" {
  source   = "./modules/ebs-csi-driver"
  for_each = local.k8s_clusters

  region        = each.value.region
  kubeconfig    = module.talos[each.key].kubeconfig_raw
  cluster_ready = data.talos_cluster_health.this[each.key].id
}

module "node_roles" {
  source   = "./modules/node-roles"
  for_each = local.k8s_clusters

  kubeconfig    = module.talos[each.key].kubeconfig_raw
  cluster_ready = data.talos_cluster_health.this[each.key].id

  nodes = {
    for key, node in module.nodes[each.key].node_instances : key => {
      instance_id = module.nodes[each.key].instances[key].id
      role_labels = node.node_role_labels
    }
  }
}

# Reconcile runtime taints after the health check; registration taints ride the machine config
module "node_taints" {
  source   = "./modules/node-taints"
  for_each = local.k8s_clusters

  kubeconfig    = module.talos[each.key].kubeconfig_raw
  cluster_ready = data.talos_cluster_health.this[each.key].id

  nodes = {
    for key, node in module.nodes[each.key].node_instances : key => {
      instance_id    = module.nodes[each.key].instances[key].id
      runtime_taints = node.runtime_taints
    }
  }
}
