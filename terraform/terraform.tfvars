# Terraform Variables for Stock API Function App
# This file contains default values for the deployment

# Project configuration
project_name = "metrc-api-app"
environment  = "dev"
location     = "East US"
owner_email  = "elijah.ops1@gmail.com"

# Application Insights retention (free tier: 90 days max recommended)
app_insights_retention_days = 90

# CORS configuration - adjust for your domain requirements
cors_allowed_origins = ["*"]

# API configuration
api_timeout_seconds = 30
time_zone          = "UTC"

# Deployment features
enable_staging_slot = false  # Set to true if you want blue-green deployments
enable_deletion_protection = true  # Protect critical resources from accidental deletion
