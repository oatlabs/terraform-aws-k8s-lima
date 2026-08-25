variable "name_prefix" {
  description = "Prefix for the EBS CSI IAM policy name (typically the length-safe cluster name)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the EBS CSI IAM policy. IAM is account-global, so these are the only marker of which cluster a policy belongs to besides its name."
  type        = map(string)
  default     = {}
}
