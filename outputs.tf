output "talosconfig" {
  description = "The generated talosconfig, per cluster."
  value       = { for name, cluster in module.talos : name => cluster.talosconfig }
  sensitive   = true
}

output "kubeconfig" {
  description = "The generated kubeconfig, per cluster."
  value       = { for name, cluster in module.talos : name => cluster.kubeconfig_raw }
  sensitive   = true
}
