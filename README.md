# Kubernetes Lima Edition

[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform&logoColor=white)](https://registry.terraform.io/modules/oatlabs/k8s-lima/aws/latest)
[![CI](https://github.com/oatlabs/terraform-aws-k8s-lima/actions/workflows/ci.yml/badge.svg)](https://github.com/oatlabs/terraform-aws-k8s-lima/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

**The internet's most wanted and missing Kubernetes edition.**

### Minimal feature set

1. Own the control plane
2. Declarative approach to scaling nodes.
3. Out of the box plumbing:
  - EBS for supporting volume claims
  - CCM for node labels (zone and region topology keys, IAM permissions, etc)
  - NLB for supporting Load Balancer Services 

## Requirements

Terraform >= 1.9, AWS credentials that can create VPC, EC2, IAM and ELB resources, and
`bash`, `kubectl` and `helm` on the machine running. 

## Usage

```hcl
module "cluster" {
  source  = "oatlabs/k8s-lima/aws"
  version = "0.0.1"

  config = file("path/to/local/config.json")
}
```

See a full working [example](examples/marvel-production/README.md).

Until 0.1.0 is reched, pin the version exactly while the module is on `0.0.x` - the `config` schema may change in
any release, a patch included.

## License

Apache-2.0. See [LICENSE](LICENSE).
