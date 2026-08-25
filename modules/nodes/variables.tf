variable "region" {
  description = "Region to place this cluster's nodes in, and to select the region-specific Talos AMI. Stated per resource rather than taken from the provider so one aws provider can build clusters in different regions."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for node instance names (typically the length-safe cluster name)."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet ID for each availability zone a node may declare. Nodes always run in the public subnet, so a node names only its zone."
  type        = map(string)
}

variable "security_group_id" {
  description = "Security group attached to every node instance."
  type        = string
}

variable "iam_role_policies" {
  description = "IAM policies to attach to each node's instance-profile role, keyed by node role (controlplane / worker)."
  type        = map(map(string))
}

variable "k8s_control_plane" {
  description = "Control plane nodes, keyed by the node's stable name."
  type = map(object({
    instance_type     = string
    root_volume_size  = number
    monitoring        = bool
    availability_zone = string
    tags              = optional(map(string), {})
    registration_taints = optional(list(object({
      key    = string
      value  = optional(string, "")
      effect = string
    })), [])
    runtime_taints = optional(list(object({
      key    = string
      value  = optional(string, "")
      effect = string
    })), [])
    roles  = optional(list(string), [])
    labels = optional(map(string), {})
  }))

  validation {
    condition     = length(var.k8s_control_plane) > 0
    error_message = "k8s_control_plane must define at least one node."
  }

  validation {
    condition = alltrue([
      for node in values(var.k8s_control_plane) : contains(keys(var.public_subnet_ids), node.availability_zone)
    ])
    error_message = "Every k8s_control_plane availability_zone must be one the cluster declares a subnet in: ${join(", ", keys(var.public_subnet_ids))}."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for taint in node.registration_taints : contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], taint.effect)
      ]
    ]))
    error_message = "Every k8s_control_plane registration_taints effect must be NoSchedule, PreferNoSchedule or NoExecute. Kubernetes accepts no others and the spelling is case-sensitive."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for taint in node.registration_taints : can(regex("^(([a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?\\.)*[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?/)?[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$", taint.key))
      ]
    ]))
    error_message = "Every k8s_control_plane registration_taints key must be a Kubernetes qualified name: up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric, optionally prefixed by a DNS subdomain and a slash as in node-role.kubernetes.io/postgres."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for taint in node.registration_taints : can(regex("^([A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?)?$", taint.value))
      ]
    ]))
    error_message = "Every k8s_control_plane registration_taints value must be a Kubernetes label value: empty, or up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for taint in node.runtime_taints : contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], taint.effect)
      ]
    ]))
    error_message = "Every k8s_control_plane runtime_taints effect must be NoSchedule, PreferNoSchedule or NoExecute. Kubernetes accepts no others and the spelling is case-sensitive."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for taint in node.runtime_taints : can(regex("^(([a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?\\.)*[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?/)?[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$", taint.key))
      ]
    ]))
    error_message = "Every k8s_control_plane runtime_taints key must be a Kubernetes qualified name: up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric, optionally prefixed by a DNS subdomain and a slash as in node-role.kubernetes.io/postgres."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for taint in node.runtime_taints : can(regex("^([A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?)?$", taint.value))
      ]
    ]))
    error_message = "Every k8s_control_plane runtime_taints value must be a Kubernetes label value: empty, or up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric."
  }

  validation {
    condition = alltrue([
      for node in values(var.k8s_control_plane) :
      length(distinct([for taint in concat(node.registration_taints, node.runtime_taints) : "${taint.key}:${taint.effect}"])) == length(node.registration_taints) + length(node.runtime_taints)
    ])
    error_message = "A k8s_control_plane node declares the same taint key and effect twice, either within one list or across registration_taints and runtime_taints. Kubernetes identifies a taint by that pair, so the second is not an override: remove it, give it a different effect, or pick the one list the taint belongs in."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for key in keys(node.labels) : !can(regex("^([a-z0-9-]+\\.)*(kubernetes|k8s)\\.io/", key))
      ]
    ]))
    error_message = "A k8s_control_plane label key is in the kubernetes.io or k8s.io domain, which a node is not allowed to set on itself: the NodeRestriction admission plugin rejects it and the label would silently never appear. Role labels belong in the node's roles list, which applies node-role.kubernetes.io/<role> with cluster-admin credentials after the cluster is healthy."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for key in keys(node.labels) : can(regex("^(([a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?\\.)*[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?/)?[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$", key))
      ]
    ]))
    error_message = "Every k8s_control_plane label key must be a Kubernetes qualified name: up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric, optionally prefixed by a DNS subdomain and a slash as in example.com/tier."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for value in values(node.labels) : can(regex("^([A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?)?$", value))
      ]
    ]))
    error_message = "Every k8s_control_plane label value must be a Kubernetes label value: empty, or up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_control_plane) : [
        for role in node.roles : can(regex("^[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$", role))
      ]
    ]))
    error_message = "Every k8s_control_plane role must be a bare name such as \"postgres\", not a full label key: the node-role.kubernetes.io/ prefix is added for you. Up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric, and no slash."
  }

  validation {
    condition = alltrue([
      for node in values(var.k8s_control_plane) : length(distinct(node.roles)) == length(node.roles)
    ])
    error_message = "A k8s_control_plane node lists the same role twice. Each role becomes one node-role.kubernetes.io/<role> label, so a repeat is a config error rather than an override."
  }
}

variable "k8s_workers" {
  description = "Worker nodes, keyed by the node's stable name."
  type = map(object({
    instance_type     = string
    root_volume_size  = number
    monitoring        = bool
    availability_zone = string
    tags              = optional(map(string), {})
    registration_taints = optional(list(object({
      key    = string
      value  = optional(string, "")
      effect = string
    })), [])
    runtime_taints = optional(list(object({
      key    = string
      value  = optional(string, "")
      effect = string
    })), [])
    roles  = optional(list(string), [])
    labels = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for node in values(var.k8s_workers) : contains(keys(var.public_subnet_ids), node.availability_zone)
    ])
    error_message = "Every k8s_workers availability_zone must be one the cluster declares a subnet in: ${join(", ", keys(var.public_subnet_ids))}."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for taint in node.registration_taints : contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], taint.effect)
      ]
    ]))
    error_message = "Every k8s_workers registration_taints effect must be NoSchedule, PreferNoSchedule or NoExecute. Kubernetes accepts no others and the spelling is case-sensitive."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for taint in node.registration_taints : can(regex("^(([a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?\\.)*[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?/)?[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$", taint.key))
      ]
    ]))
    error_message = "Every k8s_workers registration_taints key must be a Kubernetes qualified name: up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric, optionally prefixed by a DNS subdomain and a slash as in node-role.kubernetes.io/postgres."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for taint in node.registration_taints : can(regex("^([A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?)?$", taint.value))
      ]
    ]))
    error_message = "Every k8s_workers registration_taints value must be a Kubernetes label value: empty, or up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for taint in node.runtime_taints : contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], taint.effect)
      ]
    ]))
    error_message = "Every k8s_workers runtime_taints effect must be NoSchedule, PreferNoSchedule or NoExecute. Kubernetes accepts no others and the spelling is case-sensitive."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for taint in node.runtime_taints : can(regex("^(([a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?\\.)*[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?/)?[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$", taint.key))
      ]
    ]))
    error_message = "Every k8s_workers runtime_taints key must be a Kubernetes qualified name: up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric, optionally prefixed by a DNS subdomain and a slash as in node-role.kubernetes.io/postgres."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for taint in node.runtime_taints : can(regex("^([A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?)?$", taint.value))
      ]
    ]))
    error_message = "Every k8s_workers runtime_taints value must be a Kubernetes label value: empty, or up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric."
  }

  validation {
    condition = alltrue([
      for node in values(var.k8s_workers) :
      length(distinct([for taint in concat(node.registration_taints, node.runtime_taints) : "${taint.key}:${taint.effect}"])) == length(node.registration_taints) + length(node.runtime_taints)
    ])
    error_message = "A k8s_workers node declares the same taint key and effect twice, either within one list or across registration_taints and runtime_taints. Kubernetes identifies a taint by that pair, so the second is not an override: remove it, give it a different effect, or pick the one list the taint belongs in."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for key in keys(node.labels) : !can(regex("^([a-z0-9-]+\\.)*(kubernetes|k8s)\\.io/", key))
      ]
    ]))
    error_message = "A k8s_workers label key is in the kubernetes.io or k8s.io domain, which a node is not allowed to set on itself: the NodeRestriction admission plugin rejects it and the label would silently never appear. Role labels belong in the node's roles list, which applies node-role.kubernetes.io/<role> with cluster-admin credentials after the cluster is healthy."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for key in keys(node.labels) : can(regex("^(([a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?\\.)*[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?/)?[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$", key))
      ]
    ]))
    error_message = "Every k8s_workers label key must be a Kubernetes qualified name: up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric, optionally prefixed by a DNS subdomain and a slash as in example.com/tier."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for value in values(node.labels) : can(regex("^([A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?)?$", value))
      ]
    ]))
    error_message = "Every k8s_workers label value must be a Kubernetes label value: empty, or up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric."
  }

  validation {
    condition = alltrue(flatten([
      for node in values(var.k8s_workers) : [
        for role in node.roles : can(regex("^[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$", role))
      ]
    ]))
    error_message = "Every k8s_workers role must be a bare name such as \"postgres\", not a full label key: the node-role.kubernetes.io/ prefix is added for you. Up to 63 characters of alphanumerics, hyphen, underscore or dot, starting and ending alphanumeric, and no slash."
  }

  validation {
    condition = alltrue([
      for node in values(var.k8s_workers) : length(distinct(node.roles)) == length(node.roles)
    ])
    error_message = "A k8s_workers node lists the same role twice. Each role becomes one node-role.kubernetes.io/<role> label, so a repeat is a config error rather than an override."
  }
}

variable "extra_tags" {
  description = "Extra tags to add to every node instance."
  type        = map(string)
  default     = {}
}

variable "ccm_discovery_tags" {
  description = "Tags the CCM reads to recognise a node as cluster-owned (e.g. kubernetes.io/cluster/<name>)."
  type        = map(string)
  default     = {}
}

variable "talos_version" {
  description = "Talos release new nodes boot, e.g. v1.13.8. Matched exactly against the published AMI name, so a node added later joins at the version the cluster is running rather than whatever Sidero shipped that week."
  type        = string

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.talos_version))
    error_message = "talos_version must be a full v-prefixed release such as v1.13.8: the AMI name embeds all three components. modules/talos accepts vX.Y, this module does not."
  }
}
