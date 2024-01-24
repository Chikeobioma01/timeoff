# Terraform-aws-eks

# AWS Infrastructure Provisioning with Terraform

## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [Module Inputs](#module-inputs)
- [Module Outputs](#module-outputs)
- [License](#license)

## Introduction
This module is basically combination of Terraform open source and includes automatation tests and examples. It also helps to create and improve your infrastructure with minimalistic code instead of maintaining the whole infrastructure code yourself.
## Usage
To use this module, you can include it in your Terraform configuration. Here's an example of how to use it:

## Examples:-

## Example: albingress
```hcl
module "albingress" {
  source          = "git::https://github.com/cypik/terraform-eks-helm.git?ref=v1.0.0"
  name            = "alb"
  chart           = "aws-load-balancer-controller"
  repository      = "https://aws.github.io/eks-charts"
  chart_version   = "1.6.2"
  namespace       = "kube-system"
  cleanup_on_fail = true

  set = [
    {
      name  = "image.tag"
      value = "v2.6.2"
    },
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "vpcId"
      value = module.vpc.id
    },
    {
      name  = "region"
      value = "us-east-1"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.create"
      value = true
    },
    {
      name  = "replicaCount"
      value = "1"
    }
  ]
}
```

## Example: autoscaler
```hcl
module "autoscaler" {
  source           = "git::https://github.com/cypik/terraform-eks-helm.git?ref=v1.0.0"
  depends_on       = [module.eks.cluster_id]
  enabled          = false
  name             = "autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  chart_version    = "9.34.1"
  namespace        = "autoscaler"
  create_namespace = true
  set = [
    {
      name  = "awsRegion"
      value = "us-east-1"
    },
    {
      name  = "autoscalingGroups[0].name"
      value = data.aws_autoscaling_groups.groups.names[0]
    },
    {
      name  = "autoscalingGroups[0].maxSize"
      value = 4
    },
    {
      name  = "autoscalingGroups[0].minSize"
      value = 1
    },
    {
      name  = "autoscalingGroups[1].name"
      value = data.aws_autoscaling_groups.groups.names[1]
    },
    {
      name  = "autoscalingGroups[1].                                                                            "
      value = 3
    },
    {
      name  = "autoscalingGroups[1].minSize"
      value = 1
    }
  ]
}
```

## Example: ingress_nginx
```hcl
module "ingress_nginx" {
  source           = "git::https://github.com/cypik/terraform-eks-helm.git?ref=v1.0.0"
  name             = "nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart_version    = "4.9.0"
  create_namespace = true
  set = [
    {
      name  = "image.tag"
      value = "v2.5.1"
    },
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "vpcId"
      value = module.vpc.id
    },
    {
      name  = "region"
      value = "us-east-1"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.create"
      value = true
    },
    {
      name  = "replicaCount"
      value = "1"
    }
  ]
}
```
## Module Inputs
- `name`  : Release name. The length must not be longer than 53 characters.
- `chart` : Chart name to be installed.
- `repository` : Repository URL where to locate the requested chart.
- `chart_version`:  lag to control the cluster_enabled creation.
- `namespace`:  The namespace to install the release into. Defaults to default.
- `value`: List of values in raw yaml to pass to helm. Values will be merged, in order, as Helm does with multiple -f options.
- `create_namespace`: Create the namespace if it does not yet exist. Defaults to false.

For security group settings, you can configure the ingress and egress rules using variables like:

## Module Outputs
- `name` : Name is the name of the release.
- `chart` : The name of the chart.
- `namespace` :  Namespace is the kubernetes namespace of the release.
- `version` : Specify the exact chart version to install. If this is not specified, the latest version is installed.
- `manifest`: The rendered manifest of the release as JSON. Enable the manifest experiment to use this feature.
- `status`: Status of the release.
- `repository`:  Repository URL where to locate the requested chart.
- `values`: List of values in raw yaml to pass to helm. Values will be merged, in order, as Helm does with multiple -f options.

## Example
For detailed examples on how to use this module, please refer to the [Examples](https://github.com/cypik/terraform-helm-nginx-ingress/tree/master/example) directory within this repository.

## Author
Your Name Replace '[License Name]' and '[Your Name]' with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.

## License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/cypik/terraform-helm-nginx-ingress/blob/master/LICENSE) file for details.
