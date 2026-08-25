resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "roles" {
  for_each = toset([for node in values(var.node_instances) : node.role])

  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_endpoint}"
  machine_type       = each.key
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches     = var.config_patches
}

resource "talos_machine_configuration_apply" "nodes" {
  for_each = var.node_instances

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.roles[each.value.role].machine_configuration
  config_patches              = try(var.node_config_patches[each.key], null)
  endpoint                    = var.instances[each.key].public_ip
  node                        = var.instances[each.key].private_ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.nodes]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = var.instances[var.controlplane_keys[0]].public_ip
  node                 = var.instances[var.controlplane_keys[0]].private_ip
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for key in var.controlplane_keys : var.instances[key].public_ip]
  nodes = concat(
    [for key in var.controlplane_keys : var.instances[key].public_ip],
    [for key in var.worker_keys : var.instances[key].private_ip],
  )
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = var.instances[var.controlplane_keys[0]].public_ip
  node                 = var.instances[var.controlplane_keys[0]].private_ip
}
