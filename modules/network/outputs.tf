output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet ID for each availability zone. The private tier, when it exists, is not for Kubernetes and gets its own output."
  value       = { for az in keys(var.subnets) : az => aws_subnet.this["${az}.public"].id }
}

output "cluster_security_group_id" {
  description = "ID of the security group allowing intra-cluster, Talos API, and egress traffic."
  value       = module.cluster_sg.id
}

output "kubernetes_api_security_group_id" {
  description = "ID of the security group allowing access to the Kubernetes API load balancer."
  value       = module.kubernetes_api_sg.id
}
