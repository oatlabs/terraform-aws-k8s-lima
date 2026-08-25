locals {
  owned_annotation = "oatlabs.oatmilk.work/owned-taints"

  # kubectl taint syntax: KEY=VALUE:EFFECT, or KEY:EFFECT when the value is empty.
  taint_args = { for key, node in var.nodes : key => join(" ", sort([
    for taint in node.runtime_taints : "${taint.key}${taint.value == "" ? "" : "=${taint.value}"}:${taint.effect}"
  ])) }

  owned_keys = { for key, node in var.nodes : key => join(" ", sort([
    for taint in node.runtime_taints : "${taint.key}:${taint.effect}"
  ])) }
}

resource "terraform_data" "taints" {
  for_each = var.nodes

  triggers_replace = {
    instance_id   = each.value.instance_id
    taints        = local.taint_args[each.key]
    cluster_ready = var.cluster_ready
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      KUBECONFIG_CONTENT = var.kubeconfig
      INSTANCE_ID        = each.value.instance_id
      TAINT_ARGS         = local.taint_args[each.key]
      OWNED_KEYS         = local.owned_keys[each.key]
      OWNED_ANNOTATION   = local.owned_annotation
    }

    command = <<-EOT
      set -euo pipefail
      command -v kubectl >/dev/null || {
        echo "modules/node-taints needs the kubectl CLI on the machine running terraform" >&2
        exit 1
      }

      umask 077
      d="$(mktemp -d)"
      trap 'rm -rf "$d"' EXIT

      printf '%s' "$KUBECONFIG_CONTENT" > "$d/kubeconfig"
      export KUBECONFIG="$d/kubeconfig"

      # Match the instance id inside spec.providerID rather than rebuilding the whole
      # string: the CCM owns that format, and a mismatch here would report a node as
      # missing when it had merely joined under a spelling we did not predict.
      node="$(kubectl get nodes \
        -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.providerID}{"\n"}{end}' \
        | awk -F'\t' -v id="$INSTANCE_ID" '$2 ~ ("/" id "$") { print $1 }')"

      count="$(printf '%s' "$node" | grep -c . || true)"
      if [ "$count" -ne 1 ]; then
        echo "expected exactly one Kubernetes node whose providerID ends in $INSTANCE_ID, found $count" >&2
        exit 1
      fi

      owned="$(kubectl get node "$node" -o jsonpath="{.metadata.annotations.oatlabs\.oatmilk\.work/owned-taints}")"
      for entry in $owned; do
        case " $OWNED_KEYS " in
          *" $entry "*) ;;
          *) kubectl taint node "$node" "$entry-" || true ;;
        esac
      done

      if [ -n "$TAINT_ARGS" ]; then
        kubectl taint node "$node" $TAINT_ARGS --overwrite
      fi

      kubectl annotate node "$node" "$OWNED_ANNOTATION=$OWNED_KEYS" --overwrite
    EOT
  }
}
