<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9 |
| aws | >= 6.60 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.60 |
| terraform | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| talos\_nodes | terraform-aws-modules/ec2-instance/aws | ~> 6.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.taint_lock](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_ami.talos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| ccm\_discovery\_tags | Tags the CCM reads to recognise a node as cluster-owned (e.g. kubernetes.io/cluster/<name>). | `map(string)` | `{}` | no |
| extra\_tags | Extra tags to add to every node instance. | `map(string)` | `{}` | no |
| iam\_role\_policies | IAM policies to attach to each node's instance-profile role, keyed by node role (controlplane / worker). | `map(map(string))` | n/a | yes |
| k8s\_control\_plane | Control plane nodes, keyed by the node's stable name. | <pre>map(object({<br/>    instance_type     = string<br/>    root_volume_size  = number<br/>    monitoring        = bool<br/>    availability_zone = string<br/>    tags              = optional(map(string), {})<br/>    registration_taints = optional(list(object({<br/>      key    = string<br/>      value  = optional(string, "")<br/>      effect = string<br/>    })), [])<br/>    runtime_taints = optional(list(object({<br/>      key    = string<br/>      value  = optional(string, "")<br/>      effect = string<br/>    })), [])<br/>    roles  = optional(list(string), [])<br/>    labels = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| k8s\_workers | Worker nodes, keyed by the node's stable name. | <pre>map(object({<br/>    instance_type     = string<br/>    root_volume_size  = number<br/>    monitoring        = bool<br/>    availability_zone = string<br/>    tags              = optional(map(string), {})<br/>    registration_taints = optional(list(object({<br/>      key    = string<br/>      value  = optional(string, "")<br/>      effect = string<br/>    })), [])<br/>    runtime_taints = optional(list(object({<br/>      key    = string<br/>      value  = optional(string, "")<br/>      effect = string<br/>    })), [])<br/>    roles  = optional(list(string), [])<br/>    labels = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| name\_prefix | Prefix for node instance names (typically the length-safe cluster name). | `string` | n/a | yes |
| public\_subnet\_ids | Public subnet ID for each availability zone a node may declare. Nodes always run in the public subnet, so a node names only its zone. | `map(string)` | n/a | yes |
| region | Region to place this cluster's nodes in, and to select the region-specific Talos AMI. Stated per resource rather than taken from the provider so one aws provider can build clusters in different regions. | `string` | n/a | yes |
| security\_group\_id | Security group attached to every node instance. | `string` | n/a | yes |
| talos\_version | Talos release new nodes boot, e.g. v1.13.8. Matched exactly against the published AMI name, so a node added later joins at the version the cluster is running rather than whatever Sidero shipped that week. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| controlplane\_keys | Deterministically ordered node\_instances keys for the control plane. |
| instances | Created instances keyed by node key, each with id / public\_ip / private\_ip. |
| node\_instances | Per-node plan (role, sizing, registration and runtime taints, labels), keyed by "<group>.<name>" (name is the node's stable identity). |
| worker\_keys | Deterministically ordered node\_instances keys for the workers. |
<!-- END_TF_DOCS -->
