output "albingress_name" {
  value       = module.albingress[*].name
  description = "Release name"
}

output "albingress_chart" {
  value       = module.albingress[*].chart
  description = "Chart name to be installed"
}

output "albingressr_repository" {
  value       = module.albingress[*].repository
  description = "Repository URL where to locate the requested chart"
}