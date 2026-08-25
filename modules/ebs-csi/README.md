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

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| name\_prefix | Prefix for the EBS CSI IAM policy name (typically the length-safe cluster name). | `string` | n/a | yes |
| tags | Tags to apply to the EBS CSI IAM policy. IAM is account-global, so these are the only marker of which cluster a policy belongs to besides its name. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| iam\_role\_policies | iam\_role\_policies map for each node role. Only the control plane carries the policy; the CSI controller is pinned there and the node plugin reaches IMDS without calling the EC2 API. |
<!-- END_TF_DOCS -->