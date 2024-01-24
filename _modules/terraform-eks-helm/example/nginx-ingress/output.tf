output "ingress_name" {
  value       = module.ingress_nginx[*].name
  description = "Release name"
}

output "ingress_namespace" {
  value       = module.ingress_nginx[*].namespace
  description = "The namespace to install the release into"
}

output "ingress_chart" {
  value       = module.ingress_nginx[*].chart
  description = "Chart name to be installed"
}

output "ingress_repository" {
  value       = module.ingress_nginx[*].repository
  description = "Repository URL where to locate the requested chart"
}

output "ingress_version" {
  value       = module.ingress_nginx[*].version
  description = "The namespace to install the release into"
}

output "status" {
  value       = module.ingress_nginx.status
  description = "Status of the release."
}
output "manifest" {
  value = module.ingress_nginx.manifest
}

