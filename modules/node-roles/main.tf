locals {
  owned_annotation = "oatlabs.oatmilk.work/owned-roles"

  # Role labels carry no value, so kubectl spells them "<key>=".
  label_args = { for key, node in var.nodes : key => join(" ", [
    for label in node.role_labels : "${label}="
  ]) }

  owned_keys = { for key, node in var.nodes : key => join(" ", node.role_labels) }
}

resource "terraform_data" "roles" {
  for_each = var.nodes

  triggers_replace = {
    instance_id   = each.value.instance_id
    role_labels   = local.owned_keys[each.key]
    cluster_ready = var.cluster_ready
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      KUBECONFIG_CONTENT = var.kubeconfig
      INSTANCE_ID        = each.value.instance_id
      LABEL_ARGS         = local.label_args[each.key]
      OWNED_KEYS         = local.owned_keys[each.key]
      OWNED_ANNOTATION   = local.owned_annotation
    }

    command = <<-EOT
      set -euo pipefail
      command -v kubectl >/dev/null || {
        echo "modules/node-roles needs the kubectl CLI on the machine running terraform" >&2
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

      owned="$(kubectl get node "$node" -o jsonpath="{.metadata.annotations.oatlabs\.oatmilk\.work/owned-roles}")"
      for entry in $owned; do
        case " $OWNED_KEYS " in
          *" $entry "*) ;;
          *) kubectl label node "$node" "$entry-" || true ;;
        esac
      done

      if [ -n "$LABEL_ARGS" ]; then
        kubectl label node "$node" $LABEL_ARGS --overwrite
      fi

      kubectl annotate node "$node" "$OWNED_ANNOTATION=$OWNED_KEYS" --overwrite
    EOT
  }
}
