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

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| cluster\_sg | terraform-aws-modules/security-group/aws | ~> 6.0 |
| kubernetes\_api\_sg | terraform-aws-modules/security-group/aws//modules/https-443 | ~> 6.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route.public_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| ccm\_discovery\_tags | Tags the CCM reads to recognise a subnet or security group as cluster-owned (e.g. kubernetes.io/cluster/<name>). | `map(string)` | `{}` | no |
| kubernetes\_api\_allowed\_cidr | The CIDR from which to allow access to the Kubernetes API (port 443 on the ELB). | `string` | `"0.0.0.0/0"` | no |
| name | Name applied to the VPC and security groups (typically the length-safe cluster name). | `string` | n/a | yes |
| region | Region to build this cluster's network in. Stated per resource rather than taken from the provider so one aws provider can build clusters in different regions. | `string` | n/a | yes |
| subnets | The public subnet's CIDR in each availability zone this cluster uses. Literal, not derived, so a subnet's address never moves. Kubernetes nodes run here. A private tier is not implemented — building one means giving it its own routing and tags, at which point this gains a tier level and nodes stay in the public one. | `map(string)` | n/a | yes |
| tags | Tags to apply to the VPC and security groups. | `map(string)` | `{}` | no |
| talos\_api\_allowed\_cidr | The CIDR from which to allow access to the Talos API (port 50000). | `string` | `"0.0.0.0/0"` | no |
| vpc\_cidr | The IPv4 CIDR block for the VPC. | `string` | `"172.16.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cluster\_security\_group\_id | ID of the security group allowing intra-cluster, Talos API, and egress traffic. |
| kubernetes\_api\_security\_group\_id | ID of the security group allowing access to the Kubernetes API load balancer. |
| public\_subnet\_ids | Public subnet ID for each availability zone. The private tier, when it exists, is not for Kubernetes and gets its own output. |
| vpc\_id | ID of the created VPC. |
<!-- END_TF_DOCS -->
