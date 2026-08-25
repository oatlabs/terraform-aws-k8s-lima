<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9 |

## Providers

| Name | Version |
| ---- | ------- |
| terraform | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.driver](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| chart\_version | Version of the aws-ebs-csi-driver Helm chart to install. | `string` | `"2.64.0"` | no |
| cluster\_ready | Dependency carrier, not data: a value only known once the cluster is healthy, so that the install is ordered after it. The root passes data.talos\_cluster\_health.this[...].id, which is the constant "cluster\_health". | `string` | n/a | yes |
| extra\_values | Optional additional chart values, as one YAML document. Merged after this module's values.yaml, so it wins on conflicts. Overriding controller.nodeSelector here moves the controller off the control plane, which is the only role modules/ebs-csi attaches the volume policy to. | `string` | `""` | no |
| helm\_timeout | Timeout for the helm upgrade --install. The release is --atomic, so exceeding this rolls it back and fails the apply. | `string` | `"10m"` | no |
| kubeconfig | Raw kubeconfig YAML for the cluster the driver is installed into. Reaches helm through a mktemp file that does not outlive the apply, never through the provisioner command line. | `string` | n/a | yes |
| namespace | Namespace the EBS CSI driver Helm release is installed into. | `string` | `"kube-system"` | no |
| region | Region the cluster runs in. Passed to the driver as controller.region; the CSI controller calls the EC2 API in this region. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->