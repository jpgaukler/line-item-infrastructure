variable "environment_stage" {
  description = "Environment/stage name, such as dev, qa, prod."
  type        = string
}

variable "app_name" {
  description = "Application name used for naming Auth0 resources."
  type        = string
}

variable "app_type" {
  description = "Type of client application, such as 'spa'. See docs for possible values."
  type        = string
  default     = "spa"
}

variable "app_logo_uri" {
  description = "Logo URI for the Auth0 application."
  type        = string
}

variable "grant_types" {
  description = "Allowed grant types for authentication flow. See docs for possible values."
  type        = list(string)
  default = [
    "authorization_code",
    "refresh_token"
  ]
}

variable "custom_login_domain" {
  description = "Custom domain for Auth0 login page."
  type        = string
}

variable "allowed_web_urls" {
  description = "Allowed callback, logout, origin, and web origin URLs for the Auth0 SPA client."
  type        = list(string)
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID where the Auth0 custom domain verification record should be created."
  type        = string
}