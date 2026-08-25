# Security

## Reporting a vulnerability

Report privately through GitHub's
[private vulnerability reporting](https://github.com/oatlabs/terraform-aws-k8s-lima/security/advisories/new)
rather than opening a public issue. Please include the module version, the `config` that
reproduces it, and what an attacker gains.

## What this module does with credentials

- **State holds cluster-admin credentials.** The `kubeconfig` and `talosconfig` outputs are
  marked `sensitive`, but they sit in Terraform state in cleartext, as do the Talos machine
  secrets. Anyone who can read the state file owns the cluster. Store state accordingly and
  keep `*.tfstate` out of version control — the repository's `.gitignore` does this, and no
  state file has ever been committed.
- **Nothing is persisted outside state by the module.** The only credentials written to a
  durable path are the ones you ask for: the example's `just fetch-config` recipe drops them
  into `.kube/` and `.talos/`, both gitignored.
- **Provisioners handle the kubeconfig carefully.** It reaches them as an environment
  variable rather than a command-line argument, so it never appears in process listings. Each
  one then writes it under `umask 077` into a `mktemp -d` directory and removes that
  directory with an `EXIT` trap, so it is not left behind on the runner.

## Known exposure in the default configuration

Nodes run in public subnets, and both the Kubernetes API (443 on the ELB) and the Talos API
(port 50000) accept traffic from `0.0.0.0/0`. `modules/network` takes
`kubernetes_api_allowed_cidr` and `talos_api_allowed_cidr` to narrow this, but the root
module does not currently expose them through `config`. If your threat model needs them
tightened, call `modules/network` directly.

Trivy configuration scanning runs on every pull request and weekly. Accepted findings are
recorded in `.trivyignore`, each with the reason it is acceptable here.
