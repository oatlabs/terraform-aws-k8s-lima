variable "region" {
  description = "Region the cluster runs in. Passed to the driver as controller.region; the CSI controller calls the EC2 API in this region."
  type        = string
}

variable "kubeconfig" {
  description = "Raw kubeconfig YAML for the cluster the driver is installed into. Reaches helm through a mktemp file that does not outlive the apply, never through the provisioner command line."
  type        = string
  sensitive   = true
}

variable "cluster_ready" {
  description = "Dependency carrier, not data: a value only known once the cluster is healthy, so that the install is ordered after it. The root passes data.talos_cluster_health.this[...].id, which is the constant \"cluster_health\"."
  type        = string
}

variable "chart_version" {
  description = "Version of the aws-ebs-csi-driver Helm chart to install."
  type        = string
  default     = "2.64.0"
}

variable "namespace" {
  description = "Namespace the EBS CSI driver Helm release is installed into."
  type        = string
  default     = "kube-system"
}

variable "helm_timeout" {
  description = "Timeout for the helm upgrade --install. The release is --atomic, so exceeding this rolls it back and fails the apply."
  type        = string
  default     = "10m"
}

variable "extra_values" {
  description = "Optional additional chart values, as one YAML document. Merged after this module's values.yaml, so it wins on conflicts. Overriding controller.nodeSelector here moves the controller off the control plane, which is the only role modules/ebs-csi attaches the volume policy to."
  type        = string
  default     = ""
}
