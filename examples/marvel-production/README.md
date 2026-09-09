# Run instructions

Requires `terraform`, `just`, `jq`, `helm`, `kubectl` and AWS credentials on your machine. Refer `.env.sample`.
 
Step 1: Bootstrap the Kubernetes infrastructure on AWS for all clusters in `config.json`.
```sh
just apply
```

Step 2: Fetch Kubernetes and Talos credentials for the us-west-2-aws-marvel-dataplane cluster from terraform state and save them to `.kube/` and `.talos/` respectively.
```sh
just fetch-config us-west-2-aws-marvel-dataplane
```

Step 3: Now you are ready to deploy apps with `kubectl` with the below configuration.
```bash
export KUBECONFIG=.kube/us-west-2-aws-marvel-dataplane.config
```

Step 4: To use `talosctl` for cluster administration
```bash
export TALOSCONFIG=.talos/us-west-2-aws-marvel-dataplane.config
```

# FAQ

## Create a new Kubernetes cluster

Add a cluster entry and fill up the nodes in `config.json`, then run `just apply`.

## Add capacity units to existing cluster

Add a node entry to an existig cluster in `config.json`, then run `just apply`.

## Dedicate a node to a workload

Give the node a taint to keep everything else off, a role so workloads can select it, and
any labels you want. Then run `just apply`.

```json
"node-1": {
  "instance_type": "c7i-flex.large",
  "root_volume_size": 30,
  "monitoring": false,
  "availability_zone": "us-west-2a",
  "registration_taints": [
    { "key": "node-role.kubernetes.io/postgres", "effect": "NoSchedule" }
  ],
  "roles": ["postgres"],
  "labels": { "oatlabs.oatmilk.work/tier": "db" }
}
```

`roles` and `labels` can be edited whenever you like. `registration_taints` cannot: they are
read only when the node registers, so a later edit fails the plan and tells you what to do
instead. That rigidity is the point here — the taint is on the node from the instant it
joins, so nothing can land on it in the meantime.

Tainting a **control plane** node also strands the EBS CSI controller, which is pinned there
and tolerates only `node-role.kubernetes.io/control-plane`.

## Dedicate a node to a workload, reversibly

Use `runtime_taints` when the dedication is one you expect to move — trialling a node for a
workload before committing to it, or shifting a reservation between nodes that already exist.
Same shape as `registration_taints`, but applied once the cluster is healthy and editable on
any apply.

```json
"node-0": {
  "instance_type": "c7i-flex.large",
  "root_volume_size": 30,
  "monitoring": false,
  "availability_zone": "us-west-2c",
  "runtime_taints": [
    { "key": "oatlabs.oatmilk.work/workload", "value": "ingress", "effect": "NoSchedule" }
  ],
  "roles": ["ingress"]
}
```

Only pods carrying the matching toleration land there:

```yaml
tolerations:
  - key: oatlabs.oatmilk.work/workload
    value: ingress
    effect: NoSchedule
```

Move the reservation by moving those four lines to another node and running `just apply`;
remove them to hand the node back to everything else.

To take a node out of service briefly, use `kubectl cordon` instead — that is what it is for.

The trade against `registration_taints` is the gap: between the node joining and Terraform
reaching the reconciler, the node carries no runtime taint, so a pod can land there on a
fresh bring-up. The same key and effect cannot be in both lists on one node — the plan
rejects it.

### If a NoExecute taint breaks the cluster

`runtime_taints` accepts `NoExecute`, and evicting the wrong thing can make the cluster
unhealthy. `terraform apply` then stops at the health check, which runs *before* the step
that would remove the taint, so re-applying will not fix it. Clear it by hand first:

```sh
just fetch-config
kubectl taint node <node> <key>:NoExecute-
```

Then remove it from `config.json` and `just apply`.

## Find a node by its config.json name

```sh
kubectl get nodes -L oatlabs.oatmilk.work/node-hint
kubectl get nodes -l oatlabs.oatmilk.work/node-hint=worker.node-1
```

The value is `<role>.<name>`, the same key Terraform uses in state.

## Upgrade Talos & Kubernetes versions

**Use `talosctl`, not just change versions in `config.json` and re-apply terraform configuration.**.

Refer

- [How to upgrade k8s](https://docs.siderolabs.com/kubernetes-guides/advanced-guides/upgrading-kubernetes)

- [How to upgrade Talos](https://docs.siderolabs.com/talos/v1.13/configure-your-talos-cluster/lifecycle-management/upgrading-talos#talosctl-upgrade)

- [Talos & Kubernetes version compatiblity](https://docs.siderolabs.com/talos/v1.13/getting-started/support-matrix)


**DO NOT SKIP**. 

A stale `kubernetes_version` in `config.json` can roll the control plane backwards the next time anything regenerates the machine config. Always manually upgrade the `talos_version` / `kubernetes_version` in `config.json` to match what the cluster runs.
