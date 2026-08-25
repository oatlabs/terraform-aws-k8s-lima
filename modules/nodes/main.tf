data "aws_ami" "talos" {
  region = var.region
  owners = ["540036508848"]

  filter {
    name   = "name"
    values = ["talos-${var.talos_version}-${var.region}-amd64"]
  }
}

locals {
  node_sets = {
    controlplane = var.k8s_control_plane
    worker       = var.k8s_workers
  }

  node_instances = merge([
    for role, nodes in local.node_sets : {
      for node_name, node in nodes :
      "${role}.${node_name}" => {
        role                = role
        instance_type       = node.instance_type
        root_volume_size    = node.root_volume_size
        monitoring          = node.monitoring
        tags                = node.tags
        registration_taints = node.registration_taints
        runtime_taints      = node.runtime_taints
        node_labels = merge({
          "oatlabs.oatmilk.work/node-hint" = "${role}.${node_name}"
        }, node.labels)
        node_role_labels  = sort([for r in node.roles : "node-role.kubernetes.io/${r}"])
        availability_zone = node.availability_zone
        subnet_id         = var.public_subnet_ids[node.availability_zone]
        name              = "${var.name_prefix}-${role == "controlplane" ? "control-plane" : "worker"}-${node_name}"
      }
    }
  ]...)

  # Each node's registration taints as kubectl spells them, sorted: what taint_lock records.
  taint_fingerprints = { for key, node in local.node_instances : key =>
    join(", ", sort([
      for taint in node.registration_taints : "${taint.key}${taint.value == "" ? "" : "=${taint.value}"}:${taint.effect}"
    ]))
  }

  controlplane_keys = sort([for key, node in local.node_instances : key if node.role == "controlplane"])
  worker_keys       = sort([for key, node in local.node_instances : key if node.role == "worker"])
}

module "talos_nodes" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  for_each = local.node_instances

  region                      = var.region
  name                        = each.value.name
  ami                         = data.aws_ami.talos.id
  monitoring                  = each.value.monitoring
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  iam_role_use_name_prefix    = false
  create_iam_instance_profile = true
  associate_public_ip_address = true
  iam_role_policies           = var.iam_role_policies[each.value.role]
  tags                        = merge(each.value.tags, var.extra_tags, var.ccm_discovery_tags)

  # upgrades are to be handled by `talosctl`.
  ignore_ami_changes = true

  create_security_group  = false
  vpc_security_group_ids = [var.security_group_id]

  root_block_device = {
    size = each.value.root_volume_size
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
}

# Taints are fixed at registration, so a later edit is refused rather than pushed.
resource "terraform_data" "taint_lock" {
  for_each = local.node_instances

  input = local.taint_fingerprints[each.key]

  lifecycle {
    # Never update the recorded value: it is what the node registered with.
    ignore_changes = [input]

    postcondition {
      condition = self.output == local.taint_fingerprints[each.key]

      error_message = <<-EOT
        Taints on ${each.key} cannot be changed in place. The kubelet reads them only when the node first registers, and NodeRestriction forbids it from editing them afterwards, so applying this would push a new machine configuration and change nothing on the running node.

          registered with: ${self.output == "" ? "(none)" : self.output}
          now declared:    ${local.taint_fingerprints[each.key] == "" ? "(none)" : local.taint_fingerprints[each.key]}

        To change them, rename the node in config.json (node-1 becomes node-1-pg, say). That replaces the instance, so it re-registers with the new taints. Drain a control plane node and run `talosctl reset --graceful=true` before that apply, so it leaves etcd cleanly.
      EOT
    }
  }
}
