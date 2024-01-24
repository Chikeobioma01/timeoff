# Terraform AWS Infrastructure Deployment

## Overview

This Terraform script automates the deployment of a basic AWS infrastructure, creating a Virtual Private Cloud (VPC), subnets, security groups, KMS key, Application Load Balancer (ALB), and an Elastic Kubernetes Service (EKS) cluster.

## Prerequisites

Before using this Terraform script, ensure the following prerequisites are met:

- Terraform installed on your machine.
- AWS CLI configured with appropriate credentials.
- AWS provider plugin installed for Terraform.

## Modules

### VPC Module
```hcl
module "vpc" {
   source = "./../../_modules/terraform-aws-vpc"

   vpc_enabled     = var.vpc_enabled
   enable_flow_log = var.enable_flow_log

   name        = "vpc"
   environment = var.environment
   label_order = var.label_order

   cidr_block    = var.cidr_block

}
```
Sets up the Virtual Private Cloud (VPC) with specified configurations.

### Subnets Module
```hcl
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
```
## To connect public subnets to Kubernetes:
     kubernetes.io/role/elb	1 or ``

## To connect private subnets to Kubernetes:
    kubernetes.io/role/internal-elb	1 or ``
## Common tag
Both the public and private subnets must be tagged with the cluster name as follows:
```base
kubernetes.io/cluster/${cluster-name}	owned or shared
```

Creates public and private subnets within the VPC, along with necessary resources like Internet Gateways and NAT Gateways.

### Security Group Module
```hcl
module "http_https" {
   source = "./../../_modules/terraform-aws-security-group"

   name        = "http-https"
   environment = var.environment
   label_order = var.label_order

   vpc_id        = module.vpc.vpc_id
   allowed_ip    = ["0.0.0.0/0"]
   allowed_ports = [80, 443, 22]
}
```
Defines security groups for allowing specified traffic to instances (HTTP, HTTPS, SSH).

### KMS Module
```hcl
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

```
Provisions a Key Management Service (KMS) key for encrypting Amazon EBS volumes used by EKS nodes.
# Terraform Modules: ACM and ECR

## ACM Module


```hcl
module "acm" {
   source = "./../../_modules/terraform-aws-acm"

   # Required Parameters
   name        = "certificate"
   environment = var.environment
   label_order = var.label_order

   # Optional Parameters
   enable_aws_certificate    = true
   domain_name               = ""
   subject_alternative_names = [""]
   validation_method         = "DNS"
   enable_dns_validation     = false
}
```
This Terraform module provisions an AWS ACM (Amazon Certificate Manager) certificate. The ACM module is designed to be flexible and customizable to suit different project requirements.

## ECR Module

```hcl
module "ecr" {
   source             = "./../../_modules/terraform-aws-ecr"

   # Required Parameters
   enable_private_ecr = true
   name               = ""
   environment        = var.environment

   # Optional Parameters
   scan_on_push       = true
   max_image_count    = 7
}
```
This Terraform module provisions an AWS ECR (Elastic Container Registry) repository. The ECR module is designed to create a private ECR repository with customizable options.

### ALB Module
```hcl
module "alb" {
   source = "./../../_modules/terraform-aws-alb"

   name                       = "alb"
   environment                = var.environment
   label_order                = var.label_order
   enable                     = var.enable
   internal                   = var.internal
   load_balancer_type         = var.load_balancer_type
   security_groups            = [module.http_https.security_group_ids]
   subnets                    = module.subnets.public_subnet_id
   enable_deletion_protection = var.enable_deletion_protection
   idle_timeout               = var.idle_timeout

   vpc_id    = module.vpc.vpc_id

   https_enabled            = var.https_enabled
   http_enabled             = var.http_enabled
   https_port               = var.https_port
   listener_type            = var.listener_type
   listener_certificate_arn = var.listener_certificate_arn
   target_group_port        = var.target_group_port

   target_groups = [
      {
         backend_protocol     = "HTTP"
         backend_port         = 3000
         target_type          = "instance"
         deregistration_delay = 300
         health_check = {
            enabled             = true
            interval            = 121
            path                = "/"
            port                = "traffic-port"
            healthy_threshold   = 10
            unhealthy_threshold = 10
            timeout             = 120
            protocol            = "HTTP"
            matcher             = "200-400"
         }
      }
   ]
}
```

Sets up an Application Load Balancer with specified configurations, including target groups and listener rules.

### EKS Module
```hcl
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
```

Deploys an Elastic Kubernetes Service (EKS) cluster with managed node groups. Configures EKS to use provided security groups and the KMS key for EBS volumes.

## Usage

1. Clone the repository:

   ```bash
   cd envirement/example
   terraform init
   terraform plan
   terraform apply

# Terraform Deployment for EKS Cluster

## Overview

This Terraform script is designed to deploy an Amazon EKS (Elastic Kubernetes Service) cluster along with necessary configurations. The script provides outputs with relevant information about the created resources to assist users in managing and interacting with the EKS cluster.

## Deployment

1. **Customization:**
   Before deploying in a production environment, it is crucial to customize the modules and variables according to your specific requirements. Ensure that all configurations align with your infrastructure needs.

2. **Deployment Command:**
   Execute the following command to deploy the EKS cluster using Terraform:
   ```bash
   terraform apply

## Outputs
After a successful deployment, the Terraform script provides the following information:

## EKS Cluster Information
## Cluster Name:
The name assigned to the EKS cluster.

## Cluster Endpoint:
The endpoint URL for accessing the EKS cluster.

## Cluster Certificate Authority Data:
Certificate authority data used to authenticate and secure communication with the EKS cluster.

## Kubeconfig Information:
Relevant information for configuring kubeconfig to interact with the EKS cluster using Kubernetes tools.

## Additional Notes
The Kubernetes provider configuration is set up using the output from the EKS module.



## AWS ALB Ingress Controller Deployment for Helm
This guide outlines the steps to deploy the AWS ALB Ingress Controller using Helm on an Amazon EKS cluster.

## Step 1: Create Namespace
``` bash
    kubectl create namespace kube-system
```   
## Step 2: Associate IAM OIDC Provider for EKS
```bash
   eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --approve
```
## Step 3: Create IAM Policy
```bash
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
```
## Step 4: Create Service Account
```bash
eksctl create iamserviceaccount \
    --cluster ${CLUSTER_NAME} \
    --namespace kube-system \
    --region ${AWS_REGION} \
    --name aws-load-balancer-controller \
    --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --approve
```
## Step 5: Clone CRDs File
```bash
git clone https://github.com/aws/eks-charts/blob/master/stable/aws-load-balancer-controller/crds/crds.yaml
```
## Step 6: Apply CRDs
```bash
kubectl apply -f crds.yaml
```

## Step 7: Check Applied CRDs
```bash
kubectl get pods -A
```

## Step 8: Check Ingress
```bash
kubectl get ing -A
```
## Step 9: Deploy AWS ALB Helm Chart
```bash
helm repo add eks https://aws.github.io/eks-charts
```
## Step 10: Helm Upgrade
```bash
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
    --set clusterName=<CLUSTER_NAME> \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set image.tag="<LBC_VERSION>" \
    --set replicaCount=1
```

# Timeoff Environment Deployment Workflows

## Overview

This GitHub Actions workflow automates the deployment process for the "timeoff" application to an Amazon EKS cluster. The workflow is triggered on pushes to the 'timeoff' branch and can also be manually triggered.

## Workflow Steps

1. **Checkout**: Clones the repository for further processing.

2. **Configure AWS Credentials**: Sets up AWS credentials to interact with AWS services.
![Monica_2024-01-24_17-42-28.png](images%2FMonica_2024-01-24_17-42-28.png)

3. **Login EKS Cluster**: Logs into the specified Amazon EKS cluster.

4. **Login To Amazon ECR**: Logs into Amazon Elastic Container Registry (ECR) to push Docker images.

5. **Prepare Docker Images and push to Amazon ECR**: Builds Docker images for the application, tags them, and pushes them to Amazon ECR.

6. **Deploy to timeoff**: Upgrades or installs the application on the Kubernetes cluster using Helm, specifying the new Docker image tag.

## Prerequisites

- AWS Access Key ID and Secret Access Key must be set up as GitHub secrets (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY).
- The Amazon EKS cluster named 'eks-prod' in the 'ap-south-1' region is used.
- Docker images are stored in the Amazon ECR repository named '-''.
- Helm charts for the 'timeoff' application are located in the '_infra/helm/timeoff' directory.

## Usage

1. Push to the 'timeoff' branch or manually trigger the workflow.

2. The workflow will automatically:

   - Build Docker images.
   - Push Docker images to Amazon ECR.
   - Deploy the updated application to the Amazon EKS cluster.

## Environment Variables

- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`: AWS credentials for accessing EKS and ECR.
- `ECR_REGISTRY`: Amazon ECR registry URL.
- `ECR_REPOSITORY`: Amazon ECR repository name.
- `IMAGE_TAG`: Docker image tag generated from the GitHub run ID.

## helm 
Helm charts stored on _infra directory and values are stored in values/values.yaml 
```hcl

image:
  repository: <change to ecr repo > # this is managing with gituhb actions
  pullPolicy: Always
  # Overrides the image tag whose default is the chart appVersion.
  tag: "" #this is managing with gituhb actions

## Istio virtual service and gateway configurations.


ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/load-balancer-name: eks-alb
    alb.ingress.kubernetes.io/group.name: timeoff-alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: < > #todo need to replace ACM ARN
    alb.ingress.kubernetes.io/ssl-policy: 'ELBSecurityPolicy-TLS-1-2-Ext-2018-06'
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    alb.ingress.kubernetes.io/load-balancer-attributes: 'idle_timeout.timeout_seconds=600,routing.http2.enabled=true,routing.http.drop_invalid_header_fields.enabled=true'
  hosts:
    - host: #todo chnage domain name here 
      paths:
        - path: /*
          pathType: ImplementationSpecific
  tls: []

# autoscaling 
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 40
  targetCPUUtilizationPercentage: 70

# PodDisruptionBudget
pdb:
  enabled: true

resources:
  requests:
    cpu: 150m

```

## Diagram
   ![diegram.jpeg](images%2Fdiegram.jpeg)