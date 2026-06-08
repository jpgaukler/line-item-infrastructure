variable "environment_stage" {
  description = "Environment/stage name, such as dev, qa, prod."
  type        = string
}

variable "app_name" {
  description = "Application name used for resource naming."
  type        = string
}

variable "github_actions_user_name" {
  description = "Username of the IAM user for CI/CD to push images and update the ECS service."
  type        = string
}

variable "ecr_repository_arn" {
  description = "The ARN for the container registry to pull images from."
  type        = string
}

variable "ecr_repository_url" {
  description = "The URL for the container registry to pull images from."
  type        = string
}

variable "container_cpu" {
  description = "CPU units for the ECS Express Gateway primary container."
  type        = number
}

variable "container_memory" {
  description = "Memory in MiB for the ECS Express Gateway primary container."
  type        = number
}

variable "container_port" {
  description = "Port exposed by the primary container."
  type        = number
  default     = 8080
}

variable "container_image_tag" {
  description = "Container image tag used by Terraform for the initial ECS service image."
  type        = string
  default     = "latest"
}

variable "container_health_check_path" {
  description = "HTTP health check path for the ECS Express Gateway service."
  type        = string
  default     = "/health"
}

variable "container_environment_variables" {
  description = "Environment variables to set on the primary container."
  type        = map(string)
  default     = {}
}

variable "container_secrets" {
  description = "Secrets to expose to the primary container. Map key is the env var name, value is the secret ARN/reference."
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to supported resources."
  type        = map(string)
  default     = {}
}