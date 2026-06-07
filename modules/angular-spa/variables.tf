variable "environment_stage" {
  description = "Environment/stage name, such as dev, qa, prod."
  type        = string
}

variable "app_name" {
  description = "Application name used for naming resources."
  type        = string
}

variable "app_domains" {
  description = "Fully-qualified domain names for the frontend app."
  type        = set(string)
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID where the app DNS record should be created."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the CloudFront distribution. This certificate must be in us-east-1."
  type        = string
}

variable "cloudfront_geo_restriction_locations" {
  description = "List of country codes allowed by CloudFront geo restriction."
  type        = list(string)
  default     = ["US"]
}

variable "cloudfront_price_class" {
  description = "A cost-saving setting that restricts your content delivery to specific AWS Edge locations."
  type        = string
  default     = "PriceClass_100" // US, Canada, Europe, and Israel
}

variable "github_actions_user_name" {
  description = "Username of the IAM user for CI/CD to deploy the application files."
  type        = string
}

variable "tags" {
  description = "Tags to apply to supported resources."
  type        = map(string)
  default     = {}
}