variable "environment_stage" {
  description = "Environment/stage name, such as dev, qa, prod."
  type        = string
}

variable "api_name" {
  description = "API name used for naming Auth0 resources."
  type        = string
}

variable "api_audience" {
  description = "Unique Auth0 API identifier/audience."
  type        = string
}

variable "token_lifetime" {
  description = "Number of seconds during which access tokens issued for this resource server from the token endpoint remain valid."
  type        = number
  default     = 86400 # 24 hours
}

variable "token_lifetime_for_web" {
  description = "Number of seconds during which access tokens issued for this resource server via implicit or hybrid flows remain valid. Cannot be greater than the token_lifetime value."
  type        = number
  default     = 7200 # 2 hours
}

variable "client_grants" {
  description = "Auth0 clients authorized to access this API."
  type = map(object({
    client_id        = string
    subject_type     = optional(string, "user")
    allow_all_scopes = optional(bool, true)
    scopes           = optional(list(string), [])
  }))
}

variable "api_scopes" {
  description = "Auth0 API permissions/scopes."
  type = list(object({
    name        = string
    description = string
  }))
}

variable "api_roles" {
  description = "Auth0 roles and their API permissions."
  type = map(object({
    name        = string
    description = optional(string, null)
    permissions = list(string)
  }))

  validation {
    condition = alltrue(flatten([
      for role in values(var.api_roles) : [
        for permission in role.permissions :
        contains([for scope in var.api_scopes : scope.name], permission)
      ]
    ]))
    error_message = "Each api_roles permission must match one of the names declared in api_scopes."
  }
}

variable "custom_claims_namespace" {
  description = "Namespace used for custom access token claims. Must be unique to not conflict with standard OIDC claims."
  type        = string
}