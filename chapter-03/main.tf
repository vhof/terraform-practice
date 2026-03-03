variable "bucket" {
  description = "Name of the AWS S3 bucket storing the Terraform state"
  type        = string
}

# DEPRECATED
# variable "lock_table_name" {
#   description = "Name of the AWS DynamoDB table storing the Terraform state lock"
#   type        = string
# }

provider "aws" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket

  # Prevent accidental deletion of this S3 bucket
  lifecycle { prevent_destroy = true }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Explicitly block all public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DEPRECATED
# DynamoDB table for locking Terraform state file
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = var.lock_table_name
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }

# Configure Terraform remote backend in S3 bucket
terraform {
  backend "s3" {
    key = "global/s3/terraform.tfstate"
  }
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}

# DEPRECATED
# output "dynamodb_table_name" {
#   value       = aws_dynamodb_table.terraform_locks.name
#   description = "The name of the DynamoDB table"
# }
