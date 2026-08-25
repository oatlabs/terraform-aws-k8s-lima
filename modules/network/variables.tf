variable "region" {
  description = "Region to build this cluster's network in. Stated per resource rather than taken from the provider so one aws provider can build clusters in different regions."
  type        = string
}

variable "name" {
  description = "Name applied to the VPC and security groups (typically the length-safe cluster name)."
  type        = string
}

variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "subnets" {
  description = "The public subnet's CIDR in each availability zone this cluster uses. Literal, not derived, so a subnet's address never moves. Kubernetes nodes run here. A private tier is not implemented — building one means giving it its own routing and tags, at which point this gains a tier level and nodes stay in the public one."
  type        = map(string)

  validation {
    condition     = length(var.subnets) > 0
    error_message = "subnets must declare at least one availability zone."
  }

  validation {
    condition     = alltrue([for az in keys(var.subnets) : startswith(az, var.region)])
    error_message = "Every subnets availability zone must be in this cluster's own region (${var.region}). Not in it: ${join(", ", [for az in keys(var.subnets) : az if !startswith(az, var.region)])}. A cluster's zones and its region are both stated in its config.json entry and must agree."
  }

  validation {
    condition     = alltrue([for cidr in values(var.subnets) : can(cidrnetmask(cidr))])
    error_message = "Every subnet must be a CIDR such as 172.16.0.0/20. Malformed: ${join(", ", [for az, cidr in var.subnets : "${az} = ${cidr}" if !can(cidrnetmask(cidr))])}."
  }
}

variable "talos_api_allowed_cidr" {
  description = "The CIDR from which to allow access to the Talos API (port 50000)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "kubernetes_api_allowed_cidr" {
  description = "The CIDR from which to allow access to the Kubernetes API (port 443 on the ELB)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Tags to apply to the VPC and security groups."
  type        = map(string)
  default     = {}
}

variable "ccm_discovery_tags" {
  description = "Tags the CCM reads to recognise a subnet or security group as cluster-owned (e.g. kubernetes.io/cluster/<name>)."
  type        = map(string)
  default     = {}
}
