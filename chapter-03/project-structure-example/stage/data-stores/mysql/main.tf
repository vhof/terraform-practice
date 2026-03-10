provider "aws" {}

terraform {
  backend "s3" {
    key = "stage/data-stores/mysql/terraform.tfstate"
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  db_name             = "example_database"
  skip_final_snapshot = true # For learning. Destroy fails otherwise.

  # How should we set the username and password?
  username = var.db_username
  password = var.db_password
}
