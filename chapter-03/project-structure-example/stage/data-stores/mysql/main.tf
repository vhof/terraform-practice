provider "aws" {}

# Remote state backend
terraform {
  backend "s3" {
    key = "stage/data-stores/mysql/terraform.tfstate"

    # backend-configs:
    # bucket       = "terraform-up-and-running-state-vhof"
    # use_lockfile = true 
    # encrypt      = true
  }
}

# A simple MySQL database
resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  db_name             = "example_database"
  skip_final_snapshot = true # For learning. Destroy fails otherwise.

  # For convenience, I've stored these in environment variables;
  # TF_VAR_db_username
  # TF_VAR_db_password
  username = var.db_username
  password = var.db_password
}
