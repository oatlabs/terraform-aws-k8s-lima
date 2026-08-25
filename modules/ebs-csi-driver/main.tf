locals {
  values = file("${path.module}/values.yaml")
}

resource "terraform_data" "driver" {
  triggers_replace = {
    chart_version = var.chart_version
    namespace     = var.namespace
    region        = var.region
    values_sha    = sha256("${local.values}\n${var.extra_values}")
    cluster_ready = var.cluster_ready
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      KUBECONFIG_CONTENT = var.kubeconfig
      VALUES_CONTENT     = local.values
      EXTRA_VALUES       = var.extra_values
      CHART_VERSION      = var.chart_version
      NAMESPACE          = var.namespace
      REGION             = var.region
      HELM_TIMEOUT       = var.helm_timeout
    }

    command = <<-EOT
      set -euo pipefail
      command -v helm >/dev/null || {
        echo "modules/ebs-csi-driver needs the helm CLI on the machine running terraform" >&2
        exit 1
      }

      umask 077
      d="$(mktemp -d)"
      trap 'rm -rf "$d"' EXIT

      printf '%s' "$KUBECONFIG_CONTENT" > "$d/kubeconfig"
      printf '%s' "$VALUES_CONTENT" > "$d/values.yaml"

      args=(--values "$d/values.yaml")
      if [ -n "$EXTRA_VALUES" ]; then
        printf '%s' "$EXTRA_VALUES" > "$d/extra.yaml"
        args+=(--values "$d/extra.yaml")
      fi

      KUBECONFIG="$d/kubeconfig" helm upgrade --install aws-ebs-csi-driver \
        oci://public.ecr.aws/ebs-csi-driver/charts/aws-ebs-csi-driver \
        --version "$CHART_VERSION" \
        --namespace "$NAMESPACE" \
        "$${args[@]}" \
        --set controller.region="$REGION" \
        --rollback-on-failure --timeout "$HELM_TIMEOUT"
    EOT
  }
}
