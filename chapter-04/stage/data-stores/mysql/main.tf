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
  source  = "github.com/vhof/terraform-practice//chapter-04/modules/data-stores/mysql?depth=1&ref=v0.0.1"
  stadium = local.stadium
  
  instance_type = "db.t3.micro"

  db_username = var.db_username
  db_password = var.db_password
}