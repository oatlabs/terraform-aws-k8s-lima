output "node_instances" {
  description = "Per-node plan (role, sizing, registration and runtime taints, labels), keyed by \"<group>.<name>\" (name is the node's stable identity)."
  value       = local.node_instances
}

output "controlplane_keys" {
  description = "Deterministically ordered node_instances keys for the control plane."
  value       = local.controlplane_keys
}

output "worker_keys" {
  description = "Deterministically ordered node_instances keys for the workers."
  value       = local.worker_keys
}

output "instances" {
  description = "Created instances keyed by node key, each with id / public_ip / private_ip."
  value = {
    for key, node in module.talos_nodes : key => {
      id         = node.id
      public_ip  = node.public_ip
      private_ip = node.private_ip
    }
  }
}
