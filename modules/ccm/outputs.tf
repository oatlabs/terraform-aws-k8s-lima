output "iam_role_policies" {
  description = "iam_role_policies map for each node role."
  value = {
    controlplane = {
      "${var.name_prefix}-control-plane-ccm-policy" = aws_iam_policy.control_plane.arn
    }
    worker = {
      "${var.name_prefix}-worker-ccm-policy" = aws_iam_policy.worker.arn
    }
  }
}

output "machine_config_patches" {
  description = "externalCloudProvider machine-config patch, carrying the rendered CCM manifests, applied to every node."

  value = [yamlencode({
    cluster = {
      externalCloudProvider = {
        enabled = true
      }
      inlineManifests = local.inline_manifests
    }
  })]
}
