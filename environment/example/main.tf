provider "aws" {
  region = "ca-central-1"
}

module "vpc" {
  source = "./../../_modules/terraform-aws-vpc"

  vpc_enabled     = var.vpc_enabled
  enable_flow_log = var.enable_flow_log

  name        = "vpc"
  environment = var.environment
  label_order = var.label_order

  cidr_block    = var.cidr_block

}

module "subnets" {
  source      = "./../../_modules/terrafrom-aws-subnet"
  name        = "subnet"
  environment = var.environment
  label_order = var.label_order

  availability_zones = var.availability_zones
  vpc_id              = module.vpc.vpc_id
  type                = "public-private"
  igw_id              = module.vpc.igw_id
  cidr_block          = module.vpc.vpc_cidr_block
  ipv6_cidr_block     = module.vpc.ipv6_cidr_block
  single_nat_gateway = true
}

module "http_https" {
  source = "./../../_modules/terraform-aws-security-group"

  name        = "http-https"
  environment = var.environment
  label_order = var.label_order

  vpc_id        = module.vpc.vpc_id
  allowed_ip    = ["0.0.0.0/0"]
  allowed_ports = [80, 443, 22]
}



module "kms" {
  source              = "./../../_modules/terraform-aws-kms"
  name                = "kms"
  environment         = var.environment
  enabled             = true
  description         = "KMS key for EBS of EKS nodes"
  enable_key_rotation = false
  policy              = data.aws_iam_policy_document.kms.json
}

data "aws_iam_policy_document" "kms" {
  version = "2012-10-17"
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}
#
#module "acm" {
#  source = "./../../_modules/terraform-aws-acm"
#
#  name        = "certificate"
#  environment = var.environment
#  label_order = var.label_order
#
#  enable_aws_certificate    = true
#  domain_name               = ""
#  subject_alternative_names = [""]
#  validation_method         = "DNS"
#  enable_dns_validation     = false
#}

module "ecr" {
  source             = "./../../_modules/terraform-aws-ecr"
  enable_private_ecr = true
  name               = "timeoff"
  environment        = var.environment
  scan_on_push       = true
  max_image_count    = 7
}

module "eks" {
  source      = "./../../_modules/terraform-aws-eks"
  enabled     = true
  name        = "eks"
  environment = var.environment

  # EKS
  kubernetes_version     = "1.28"
  endpoint_public_access = true
  # Networking
  vpc_id                            = module.vpc.vpc_id
  subnet_ids                        = module.subnets.private_subnet_id
  allowed_security_groups           = [module.http_https.security_group_ids]
  eks_additional_security_group_ids = [module.http_https.security_group_ids]
  allowed_cidr_blocks               = [module.vpc.vpc_cidr_block]

  managed_node_group_defaults = {
    subnet_ids                          = module.subnets.private_subnet_id
    nodes_additional_security_group_ids = [module.http_https.security_group_ids]
    tags = {
      "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
      "k8s.io/cluster/${module.eks.cluster_name}"        = "shared"
    }
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = 50
          volume_type = "gp3"
          iops        = 3000
          throughput  = 150
          encrypted   = true
          kms_key_id  = module.kms.key_arn
        }
      }
    }
  }
  managed_node_group = {
    critical = {
      name           = "critical-node"
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 2
      desired_size   = 2
      instance_types = ["t3.medium"]
    }

    application = {
      name                 = "application"
      capacity_type        = "SPOT"
      min_size             = 1
      max_size             = 2
      desired_size         = 1
      force_update_version = true
      instance_types       = ["t3.medium"]
    }
  }

  apply_config_map_aws_auth = true
  map_additional_iam_users = [
    {
      userarn  = "arn:aws:iam::123456789:user/opsstation"
      username = "test"
      groups   = ["system:masters"]
    }
  ]
}
## Kubernetes provider configuration
data "aws_eks_cluster" "this" {
  depends_on = [module.eks]
  name       = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "this" {
  depends_on = [module.eks]
  name       = module.eks.cluster_certificate_authority_data
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}


