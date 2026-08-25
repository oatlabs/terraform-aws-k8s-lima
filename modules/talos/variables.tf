variable "cluster_name" {
  description = "The Talos cluster name."
  type        = string

  validation {
    condition = (
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.cluster_name))
      && length(var.cluster_name) <= 63
    )
    error_message = "cluster_name must be a lowercase RFC 1123 label: alphanumerics and hyphens only, starting and ending with an alphanumeric, at most 63 characters. No spaces, dots, underscores, or uppercase."
  }
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint host (the API load balancer DNS name); the module prefixes https://."
  type        = string
}

variable "talos_version_contract" {
  description = "Talos version contract to generate the machine configuration against. Accepts vX.Y or vX.Y.Z — only major.minor is parsed, the patch is discarded. Does NOT control the installed Talos version; set machine.install.image via config_patches for that. null uses the contract the provider was compiled with, which moves on every provider bump."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane version. null uses the provider's compiled-in default, which is the default of the Talos machinery it vendors — not necessarily the default of the Talos release the nodes actually boot."
  type        = string
  default     = null
}

variable "config_patches" {
  description = "Machine-config patches (YAML strings) applied to every node, in precedence order. Opaque to this module."
  type        = list(string)
  default     = []
}

variable "node_instances" {
  description = "Per-node plan (the machine role to configure the node as), keyed by \"<role>.<name>\"."
  type = map(object({
    role = string
  }))
}

variable "controlplane_keys" {
  description = "Deterministically ordered node_instances keys for the control plane; [0] is the bootstrap target."
  type        = list(string)
}

variable "worker_keys" {
  description = "Deterministically ordered node_instances keys for the workers."
  type        = list(string)
}

variable "instances" {
  description = "Node addresses keyed by node key (\"<role>.<name>\")."
  type = map(object({
    public_ip  = string
    private_ip = string
  }))
}

variable "node_config_patches" {
  description = "Per-node machine-config patches (YAML strings), keyed by node key (\"<role>.<name>\"), applied on top of the role's generated configuration and after config_patches. A node with no entry gets none. Opaque to this module."
  type        = map(list(string))
  default     = {}
}
