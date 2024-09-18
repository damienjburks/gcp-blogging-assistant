variable "project_id" {
  type        = string
  description = "Project ID"
  default     = "dsb-innovation-hub"
}

variable "region" {
  type        = string
  description = "Region"
  default     = "us-central1"
}

# Secrets
variable "OPENAI_AUTH_TOKEN" {}
variable "GIT_USERNAME" {}
variable "GIT_AUTH_TOKEN" {}
variable "YOUTUBE_AUTH_TOKEN" {}
variable "PROXY_USERNAME" {}
variable "PROXY_PASSWORD" {}
