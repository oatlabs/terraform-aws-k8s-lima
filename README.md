# Kubernetes Lima Edition (Talos Linux)

[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform&logoColor=white)](https://registry.terraform.io/modules/oatlabs/k8s-lima/aws/latest)
[![CI](https://github.com/oatlabs/terraform-aws-k8s-lima/actions/workflows/ci.yml/badge.svg)](https://github.com/oatlabs/terraform-aws-k8s-lima/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)


### Minimal feature set
- Not EKS, you own the control plane. 
- No auto scaling groups, use JSON file to add nodes.
- EBS connection to allocate Persistent Volumes.
- CCM for Load Balancers requests.
- Flannel CNI for NetworkPolicy support.

## Requirements
Terraform >= 1.9, AWS credentials that can create VPC, EC2, IAM and ELB resources, and
`bash`, `kubectl` and `helm` on the machine running. 

## Usage
```hcl
module "marvel" {
  source  = "oatlabs/k8s-lima/aws"
  version = "0.0.1"

  config = file("path/to/local/config.json")
}

output "talosconfigs" {
  value       = module.marvel.talosconfigs
  sensitive   = true
}

output "kubeconfigs" {
  value       = module.marvel.kubeconfigs
  sensitive   = true
}
```
Sample [config.json](https://github.com/oatlabs/terraform-aws-k8s-lima/blob/main/examples/marvel-production/config.json) can be found here. It's part of a fully working [example](https://github.com/oatlabs/terraform-aws-k8s-lima/blob/main/examples/marvel-production).

`config.json` declares a top-level `namespace` — the environment this deployment is, such as
`staging` or `production` — and every name AWS and Talos see is `<namespace>-<cluster key>`.
Cluster keys therefore need to be unique only within their namespace, so one AWS account can
hold several environments with the same clusters in each. The two outputs are keyed by the bare
cluster key, without the namespace.

Until version `0.1.0` is reached, expect less stability as the `config` schema may change anytime. To be safe, pin the version to `0.0.x` for now.

## Credits

**Powered by Talos Linux**

## License

Apache-2.0. See [LICENSE](LICENSE).
