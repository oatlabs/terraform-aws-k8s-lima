<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9 |
| talos | >= 0.11 |

## Providers

| Name | Version |
| ---- | ------- |
| talos | >= 0.11 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.nodes](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_secrets) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/client_configuration) | data source |
| [talos_machine_configuration.roles](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| cluster\_endpoint | Kubernetes API endpoint host (the API load balancer DNS name); the module prefixes https://. | `string` | n/a | yes |
| cluster\_name | The Talos cluster name. | `string` | n/a | yes |
| config\_patches | Machine-config patches (YAML strings) applied to every node, in precedence order. Opaque to this module. | `list(string)` | `[]` | no |
| controlplane\_keys | Deterministically ordered node\_instances keys for the control plane; [0] is the bootstrap target. | `list(string)` | n/a | yes |
| instances | Node addresses keyed by node key ("<role>.<name>"). | <pre>map(object({<br/>    public_ip  = string<br/>    private_ip = string<br/>  }))</pre> | n/a | yes |
| kubernetes\_version | Kubernetes control-plane version. null uses the provider's compiled-in default, which is the default of the Talos machinery it vendors — not necessarily the default of the Talos release the nodes actually boot. | `string` | `null` | no |
| node\_config\_patches | Per-node machine-config patches (YAML strings), keyed by node key ("<role>.<name>"), applied on top of the role's generated configuration and after config\_patches. A node with no entry gets none. Opaque to this module. | `map(list(string))` | `{}` | no |
| node\_instances | Per-node plan (the machine role to configure the node as), keyed by "<role>.<name>". | <pre>map(object({<br/>    role = string<br/>  }))</pre> | n/a | yes |
| talos\_version\_contract | Talos version contract to generate the machine configuration against. Accepts vX.Y or vX.Y.Z — only major.minor is parsed, the patch is discarded. Does NOT control the installed Talos version; set machine.install.image via config\_patches for that. null uses the contract the provider was compiled with, which moves on every provider bump. | `string` | `null` | no |
| worker\_keys | Deterministically ordered node\_instances keys for the workers. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| client\_configuration | Talos client configuration (from the machine secrets), for talos data sources such as the root cluster health check. |
| kubeconfig\_raw | The generated kubeconfig (raw YAML). |
| talosconfig | The generated talosconfig. |
<!-- END_TF_DOCS -->
