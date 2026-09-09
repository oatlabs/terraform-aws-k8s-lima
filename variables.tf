variable "config" {
  description = "Whole-platform configuration as a JSON string: the organization, the namespace naming the environment this deployment is, the Talos and Kubernetes versions, and every cluster with its network layout and nodes. See example config.json for a working one; supply it with file(\"config.json\")."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\p{L}\\p{Z}\\p{N}_.:/=+@-]*$", jsondecode(var.config)["organization"]))
    error_message = "organization is used as an IAM tag value, which allows only letters, spaces, digits and _ . : / = + - @ — a stricter set than EC2 accepts. Got \"${try(jsondecode(var.config)["organization"], "")}\". An apostrophe is the usual cause."
  }

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", jsondecode(var.config)["namespace"]))
    error_message = "namespace is required, and must be a lowercase RFC 1123 label: alphanumerics and hyphens only, starting and ending with an alphanumeric. No spaces, dots, underscores, or uppercase. Got \"${try(jsondecode(var.config)["namespace"], "")}\". It prefixes every cluster name, so it lands in a Talos cluster name, a kubernetes.io/cluster/<name> tag key and an IAM tag value; the label rule is the strictest of the three. It names the environment this deployment is — staging, production — and is what lets one AWS account hold several of them. Unlike organization, which is only a tag value, this one reaches every resource name."
  }

  validation {
    condition = alltrue([
      for name in keys(try(jsondecode(var.config)["k8s_clusters"], {})) :
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", "${try(jsondecode(var.config)["namespace"], "")}-${name}"))
      && length("${try(jsondecode(var.config)["namespace"], "")}-${name}") <= 63
    ])
    error_message = "Every cluster's namespace-qualified name — \"<namespace>-<key in k8s_clusters>\" — must be a lowercase RFC 1123 label of at most 63 characters, because it is used verbatim as the Talos cluster name. Too long or malformed: ${join(", ", [for name in keys(try(jsondecode(var.config)["k8s_clusters"], {})) : "${try(jsondecode(var.config)["namespace"], "")}-${name}" if !(can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", "${try(jsondecode(var.config)["namespace"], "")}-${name}")) && length("${try(jsondecode(var.config)["namespace"], "")}-${name}") <= 63)])}. Shorten the namespace or the cluster key."
  }
}
