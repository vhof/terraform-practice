provider "aws" {}

terraform {
  backend "s3" {
    key = "stage/data-stores/mysql/terraform.tfstate"
  }
}

locals {
  stadium = "stage"
}

module "mysql" {
  source  = "../../../modules/data-stores/mysql"
  stadium = local.stadium
  
  instance_type = "db.t3.micro"

  db_username = var.db_username
  db_password = var.db_password
}