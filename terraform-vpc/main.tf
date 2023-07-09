provider "aws" {
  region = var.region
}

locals {
  name   = var.stack_name
  region = var.region
  project = var.project
  tags = {
    Owner       = var.org
    Environment = var.environment
  }
  # To identify a cluster's subnets, the Kubernetes Cloud Controller Manager (cloud-controller-manager) and AWS Load Balancer Controller (aws-load-balancer-controller) query that cluster's subnets by using the following tag as a filter
  optional_eks_cluster_tag = {
    exists = {
      "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    }
    not_exists = {}

  }
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "./terraform-aws-vpc"

#  name = "${var.project}-${var.environment}-vpc"
  name = var.stack_name
  cidr = var.vpc_cidr # 10.0.0.0/8 is reserved for EC2-Classic

  azs                 = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
  database_subnets    = var.database_subnets
  # intra subnets will host gateway endpoints, interface endpoints and eks eni endpoints
  intra_subnets       = var.intra_subnets

  create_database_subnet_group = false

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = var.enable_single_nat

  # Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  create_database_subnet_route_table = true

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  # To identify a cluster's subnets, the Kubernetes Cloud Controller Manager (cloud-controller-manager) and AWS Load Balancer Controller (aws-load-balancer-controller) query that cluster's subnets by using the following tag as a filter
  public_subnet_tags = merge(
      local.optional_eks_cluster_tag[length(var.eks_cluster_name) > 0 ? "exists" : "not_exists"],
      {
        "kubernetes.io/role/elb" = 1
      })

  private_subnet_tags =  merge(
      local.optional_eks_cluster_tag[length(var.eks_cluster_name) > 0 ? "exists" : "not_exists"],
      {
        "kubernetes.io/role/internal-elb" = 1
      })
  tags = local.tags
}

################################################################################
# VPC Endpoints Module
################################################################################

module "vpc_endpoints" {
  source = "./terraform-aws-vpc/modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [data.aws_security_group.default.id]

  endpoints = {
    s3 = {
      service = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.database_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags    = { Name = "s3-vpc-endpoint" }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.database_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      policy          = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
    sts = {
      service         = "sts"
      service_type    = "Interface"
      subnet_ids = module.vpc.intra_subnets
      security_group_ids = [ aws_security_group.endpoints_sg.id ]
    }
  }

  tags = merge(local.tags, {
    Project  = "Ecosystm"
    Endpoint = "true"
  })
}

module "vpc_endpoints_nocreate" {
  source = "./terraform-aws-vpc/modules/vpc-endpoints"
  create = false
}

################################################################################
# Supporting Resources
################################################################################

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

# Data source used to avoid race condition
data "aws_vpc_endpoint_service" "dynamodb" {
  service = "dynamodb"

  filter {
    name   = "service-type"
    values = ["Gateway"]
  }
}

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [data.aws_vpc_endpoint_service.dynamodb.id]
    }
  }
}

data "aws_iam_policy_document" "generic_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [data.aws_vpc_endpoint_service.dynamodb.id]
    }
  }
}

resource "aws_security_group" "endpoints_sg" {
  name = format("%s-%s", local.name, "interface-endpoints-sg")
  ingress {
    from_port = 443
    protocol  = "tcp"
    to_port   = 443
    cidr_blocks = [ module.vpc.vpc_cidr_block ]
  }
  vpc_id = module.vpc.vpc_id
}