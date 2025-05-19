// outputs.tf - Outputs from our Terraform configuration

output "rds_instance_endpoint" {
  description = "The connection endpoint for the RDS PostgreSQL instance."
  value       = aws_db_instance.sentinel_db.endpoint
}

output "rds_instance_port" {
  description = "The port for the RDS PostgreSQL instance."
  value       = aws_db_instance.sentinel_db.port
}

output "rds_db_name" {
  description = "The name of the database in the RDS instance."
  value       = aws_db_instance.sentinel_db.db_name
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group."
  value       = aws_security_group.rds_sg.id
}

output "backup_s3_bucket_name" {
  description = "The name of the S3 bucket created for backups."
  value       = aws_s3_bucket.backups.bucket
}

output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}
