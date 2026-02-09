output "app_config" {
  description = "Application configuration for deployment"
  value       = module.ssr.app_config
  sensitive   = true
}

output "application_url" {
  description = "Application URL"
  value       = module.ssr.application_url
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain"
  value       = module.ssr.cloudfront_domain_name
}
