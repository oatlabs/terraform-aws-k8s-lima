data "aws_availability_zones" "available" {
  region = var.region
  state  = "available"
}

locals {
  subnets = {
    for az, cidr in var.subnets : "${az}.public" => { az = az, cidr = cidr }
  }
}

resource "aws_vpc" "this" {
  region     = var.region
  cidr_block = var.vpc_cidr

  # registerWithFQDN in the CCM's machine-config patch needs VPC-provided hostnames.
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  region            = var.region
  vpc_id            = aws_vpc.this.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = merge(var.tags, var.ccm_discovery_tags, {
    Name                     = "${var.name}-${each.key}"
    "kubernetes.io/role/elb" = "1" # internet-facing LoadBalancer services land here
  })

  lifecycle {
    precondition {
      condition     = contains(data.aws_availability_zones.available.names, each.value.az)
      error_message = "${var.region} does not offer this account the availability zone ${each.value.az}. Offered: ${join(", ", data.aws_availability_zones.available.names)}. Fix the subnets block in config.json."
    }
  }
}

resource "aws_internet_gateway" "this" {
  region = var.region
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_route_table" "public" {
  region = var.region
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route" "public_internet_gateway" {
  region                 = var.region
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.this

  region         = var.region
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

module "cluster_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  region      = var.region
  name        = var.name
  description = "Allow all intra-cluster and egress traffic"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, var.ccm_discovery_tags)

  ingress_rules = {
    intra_cluster = {
      description                  = "All traffic between members of this group"
      ip_protocol                  = "-1"
      referenced_security_group_id = "self"
    }

    talos_api = {
      description = "Talos API Access"
      from_port   = 50000
      to_port     = 50000
      ip_protocol = "tcp"
      cidr_ipv4   = var.talos_api_allowed_cidr
    }
  }

  egress_rules = {
    all = {
      description = "All egress"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

module "kubernetes_api_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "~> 6.0"

  region      = var.region
  name        = "${var.name}-k8s-api"
  description = "Allow access to the Kubernetes API"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, var.ccm_discovery_tags)

  ingress_cidr_ipv4 = {
    allowed = var.kubernetes_api_allowed_cidr
  }
}
