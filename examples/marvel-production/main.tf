module "marvel" {
  source = "../../"
  config = file("${path.module}/config.json")
}

output "talosconfigs" {
  description = "The generated talosconfig, per cluster, keyed by its config.json key."
  value       = module.marvel.talosconfigs
  sensitive   = true
}

output "kubeconfigs" {
  description = "The generated kubeconfig, per cluster, keyed by its config.json key."
  value       = module.marvel.kubeconfigs
  sensitive   = true
}

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {}
