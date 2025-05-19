// main.tf - Main configuration for AWS resources

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" // Use a recent version
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

// --- Networking ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

// We need at least two availability zones for RDS
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true // Good for a bastion host or NAT Gateway if needed later

  tags = {
    Name        = "${var.project_name}-public-subnet-a"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-b"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${var.project_name}-private-subnet-a"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${var.project_name}-private-subnet-b"
    Environment = var.environment
  }
}

// Route table for public subnets to allow internet access
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

// --- RDS Database Subnet Group ---
// RDS needs a subnet group that spans at least two Availability Zones.
// We'll use our private subnets for the database.
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group-${var.environment}"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name        = "${var.project_name}-rds-subnet-group"
    Environment = var.environment
  }
}

// --- Security Group for RDS ---
// This controls what traffic can reach the RDS instance.
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Allow PostgreSQL traffic to RDS instance"
  vpc_id      = aws_vpc.main.id

  // Ingress rule: Allow PostgreSQL traffic (port 5432)
  // For now, allowing from anywhere for simplicity in CI/CD.
  // IMPORTANT: For production, restrict this to specific IPs or Security Groups
  // (e.g., your application servers, bastion hosts, or GitHub Actions runners if IPs are known).
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // WARNING: Open to the world. Restrict in production!
    // To restrict to your current IP for initial testing:
    // cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" // Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }
}

// Data source to get current AWS region's availability zones
data "aws_availability_zones" "available" {}

// Data source to get your current public IP (for restricting SG if needed)
// data "http" "myip" {
//   url = "http://ipv4.icanhazip.com"
// }


// --- RDS PostgreSQL Instance ---
// IMPORTANT: Choose instance_class and storage carefully for Free Tier / cost.
resource "aws_db_instance" "sentinel_db" {
  identifier             = "${lower(var.project_name)}-db-${lower(var.environment)}"
  engine                 = "postgres"
  engine_version         = "14" // Specify a version
  instance_class         = var.rds_instance_class // e.g., "db.t3.micro" or "db.t4g.micro" (often Free Tier eligible)
  allocated_storage      = var.rds_allocated_storage // In GB, min 20 for some types. Free Tier usually 20GB.
  storage_type           = "gp2" // General Purpose SSD

  db_name                = var.rds_db_name
  username               = var.rds_username
  password               = var.rds_password // Store this securely, e.g., via AWS Secrets Manager in production

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot    = true // Set to false for production to take a snapshot on deletion
  publicly_accessible    = true // Set to true to allow connections from outside VPC (e.g. your laptop, CI/CD)
                                // If false, you'd need a bastion host or VPC peering/endpoints.
                                // Ensure your Security Group is appropriately configured if true.

  multi_az               = false // For cost saving in dev/test. Set to true for production HA.
  backup_retention_period= 0     // For cost saving in dev/test (disables automated backups). Set to 7-35 for production.

  tags = {
    Name        = "${var.project_name}-rds-instance"
    Environment = var.environment
  }

  // Prevent accidental deletion in production
  // deletion_protection = true
}

// --- S3 Bucket for Backups ---
resource "aws_s3_bucket" "backups" {
  bucket = "${lower(var.project_name)}-db-backups-${lower(var.environment)}-${data.aws_caller_identity.current.account_id}" // Bucket names must be globally unique

  tags = {
    Name        = "${var.project_name}-db-backups"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cleanup" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "auto-delete-after-1-day"
    status = "Enabled"

    expiration {
      days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}


resource "aws_s3_bucket_public_access_block" "backups_public_access_block" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Data source to get current AWS Account ID (for unique S3 bucket name)
data "aws_caller_identity" "current" {}

