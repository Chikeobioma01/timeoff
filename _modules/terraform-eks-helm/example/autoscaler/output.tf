output "autoscaler_name" {
  value       = module.autoscaler[*].name
  description = "Release name"
}

output "autoscaler_chart" {
  value       = module.autoscaler[*].chart
  description = "Chart name to be installed"
}

output "autoscaler_repository" {
  value       = module.autoscaler[*].repository
  description = "Repository URL where to locate the requested chart"
}

output "autoscaler_namespace" {
  value       = module.autoscaler[*].namespace
  description = "The namespace to install the release into"
}

output "autoscaler_version" {
  value       = module.autoscaler[*].version
  description = "The namespace to install the release into"
}