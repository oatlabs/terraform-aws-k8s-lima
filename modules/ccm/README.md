<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9 |
| aws | >= 6.60 |
| helm | >= 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.60 |
| helm | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.control_plane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [helm_template.aws_ccm](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/data-sources/template) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| chart\_version | Version of the aws-cloud-controller-manager Helm chart to install. | `string` | `"0.0.11"` | no |
| image\_tag | Image tag (cloud-provider-aws release) for the CCM. | `string` | `"v1.36.1"` | no |
| name\_prefix | Prefix for the CCM IAM policy names (typically the length-safe cluster name). | `string` | n/a | yes |
| namespace | Namespace the CCM Helm release is installed into. | `string` | `"kube-system"` | no |
| tags | Tags to apply to the CCM IAM policies. IAM is account-global, so these are the only marker of which cluster a policy belongs to besides its name. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| iam\_role\_policies | iam\_role\_policies map for each node role. |
| machine\_config\_patches | externalCloudProvider machine-config patch, carrying the rendered CCM manifests, applied to every node. |
<!-- END_TF_DOCS -->
