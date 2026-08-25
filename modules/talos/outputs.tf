output "talosconfig" {
  description = "The generated talosconfig."
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig_raw" {
  description = "The generated kubeconfig (raw YAML)."
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "client_configuration" {
  description = "Talos client configuration (from the machine secrets), for talos data sources such as the root cluster health check."
  value       = talos_machine_secrets.this.client_configuration
  sensitive   = true
}
