variable "name_prefix" {
  description = "Prefix for the CCM IAM policy names (typically the length-safe cluster name)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the CCM IAM policies. IAM is account-global, so these are the only marker of which cluster a policy belongs to besides its name."
  type        = map(string)
  default     = {}
}

variable "chart_version" {
  description = "Version of the aws-cloud-controller-manager Helm chart to install."
  type        = string
  default     = "0.0.11"
}

variable "image_tag" {
  description = "Image tag (cloud-provider-aws release) for the CCM."
  type        = string
  default     = "v1.36.1"
}

variable "namespace" {
  description = "Namespace the CCM Helm release is installed into."
  type        = string
  default     = "kube-system"
}
