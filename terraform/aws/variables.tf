// variables.tf - Input variables for our Terraform configuration

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" // Change to your preferred region
}

variable "project_name" {
  description = "A name for the project, used for tagging and naming resources."
  type        = string
  default     = "SentinelDB"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, test, prod)."
  type        = string
  default     = "dev"
}

// RDS Variables
variable "rds_instance_class" {
  description = "The instance class for the RDS PostgreSQL instance."
  type        = string
  default     = "db.t3.micro" // Often Free Tier eligible. Check current AWS Free Tier details!
                            // Other options: db.t4g.micro (Graviton - also often Free Tier)
}

variable "rds_allocated_storage" {
  description = "The allocated storage for RDS in GB."
  type        = number
  default     = 20 // Minimum for some types, often matches Free Tier allowance.
}

variable "rds_db_name" {
  description = "The name of the database to create in the RDS instance."
  type        = string
  default     = "sentineldb"
}

variable "rds_username" {
  description = "The master username for the RDS instance."
  type        = string
  default     = "dbadmin" // Choose a username
}

variable "rds_password" {
  description = "The master password for the RDS instance. IMPORTANT: This is for learning. In production, use a secrets manager."
  type        = string
  sensitive   = true // Marks this variable as sensitive, so Terraform tries not to output it.
  // You will be prompted for this if not set via -var or a .tfvars file.
  // For CI/CD, this should come from a secure secret.
  // For local testing, you can create a terraform.tfvars file (and add it to .gitignore)
  // Example terraform.tfvars:
  // rds_password = "YourSuperSecurePassword123!"
}
