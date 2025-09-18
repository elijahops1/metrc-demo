# Input Variables for Azure Function App Infrastructure
# This file defines all the configurable parameters for the Terraform deployment

# Project Configuration
variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
  default     = "metrc-api-app"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "owner_email" {
  description = "Email of the resource owner (for tagging)"
  type        = string
  default     = "elijah.ops1@gmail.com"
}

# Application Insights Configuration
variable "app_insights_retention_days" {
  description = "Application Insights data retention period in days"
  type        = number
  default     = 90
  
  validation {
    condition     = var.app_insights_retention_days >= 30 && var.app_insights_retention_days <= 730
    error_message = "Application Insights retention must be between 30 and 730 days."
  }
}

# CORS Configuration
variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

# Application Configuration
variable "alphavantage_api_key" {
  description = "Alpha Vantage API key for stock data"
  type        = string
  default     = "demo"
  sensitive   = true
}

variable "api_timeout_seconds" {
  description = "Timeout for external API calls in seconds"
  type        = number
  default     = 30
  
  validation {
    condition     = var.api_timeout_seconds >= 5 && var.api_timeout_seconds <= 300
    error_message = "API timeout must be between 5 and 300 seconds."
  }
}

variable "time_zone" {
  description = "Time zone for the Function App"
  type        = string
  default     = "UTC"
}

# Deployment Configuration
variable "enable_staging_slot" {
  description = "Enable staging deployment slot for blue-green deployments"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on critical resources (storage, function app, app insights)"
  type        = bool
  default     = true
}