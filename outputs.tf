output "talosconfigs" {
  description = "The generated talosconfig, per cluster. Keyed by the cluster's key in config.json — bare, without the namespace prefix that qualifies the name in AWS and Talos."
  value       = { for name, cluster in module.talos : name => cluster.talosconfig }
  sensitive   = true
}

output "kubeconfigs" {
  description = "The generated kubeconfig, per cluster. Keyed by the cluster's key in config.json — bare, without the namespace prefix that qualifies the name in AWS and Talos."
  value       = { for name, cluster in module.talos : name => cluster.kubeconfig_raw }
  sensitive   = true
}
