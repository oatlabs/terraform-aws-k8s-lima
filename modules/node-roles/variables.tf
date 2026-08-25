variable "kubeconfig" {
  description = "Raw kubeconfig YAML for the cluster whose nodes are being labelled. Reaches kubectl through a mktemp file that does not outlive the apply, never through the provisioner command line."
  type        = string
  sensitive   = true
}

variable "cluster_ready" {
  description = "Dependency carrier, not data: a value only known once the cluster is healthy, so that labelling is ordered after the nodes have joined. The root passes data.talos_cluster_health.this[...].id, which is the constant \"cluster_health\"."
  type        = string
}

variable "nodes" {
  description = "Every node in the cluster, keyed by node key (\"<role>.<name>\"). instance_id is matched against the tail of the node's spec.providerID, which the CCM sets. Nodes with no role labels are included deliberately: a node whose roles were removed still needs a reconcile to strip them."
  type = map(object({
    instance_id = string
    role_labels = list(string)
  }))
}
