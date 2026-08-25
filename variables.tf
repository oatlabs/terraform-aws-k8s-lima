variable "config" {
  description = "Whole-platform configuration as a JSON string: the organization, the Talos and Kubernetes versions, and every cluster with its network layout and nodes. See example config.json for a working one; supply it with file(\"config.json\")."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\p{L}\\p{Z}\\p{N}_.:/=+@-]*$", jsondecode(var.config)["organization"]))
    error_message = "organization is used as an IAM tag value, which allows only letters, spaces, digits and _ . : / = + - @ — a stricter set than EC2 accepts. Got \"${try(jsondecode(var.config)["organization"], "")}\". An apostrophe is the usual cause."
  }
}
