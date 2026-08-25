output "iam_role_policies" {
  description = "iam_role_policies map for each node role. Only the control plane carries the policy; the CSI controller is pinned there and the node plugin reaches IMDS without calling the EC2 API."
  value = {
    controlplane = {
      "${var.name_prefix}-control-plane-ebs-csi-policy" = aws_iam_policy.ebs_csi.arn
    }
    worker = {}
  }
}
