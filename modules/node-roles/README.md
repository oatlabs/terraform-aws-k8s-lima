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
| [terraform_data.roles](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| cluster\_ready | Dependency carrier, not data: a value only known once the cluster is healthy, so that labelling is ordered after the nodes have joined. The root passes data.talos\_cluster\_health.this[...].id, which is the constant "cluster\_health". | `string` | n/a | yes |
| kubeconfig | Raw kubeconfig YAML for the cluster whose nodes are being labelled. Reaches kubectl through a mktemp file that does not outlive the apply, never through the provisioner command line. | `string` | n/a | yes |
| nodes | Every node in the cluster, keyed by node key ("<role>.<name>"). instance\_id is matched against the tail of the node's spec.providerID, which the CCM sets. Nodes with no role labels are included deliberately: a node whose roles were removed still needs a reconcile to strip them. | <pre>map(object({<br/>    instance_id = string<br/>    role_labels = list(string)<br/>  }))</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->