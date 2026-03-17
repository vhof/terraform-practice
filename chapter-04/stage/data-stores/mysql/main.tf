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
  # Terraform supports retrieving modules from remote sources. 
  # Conventionally, our modules should live in a seperate repository,
  # but I didn't feel like doing that. So, this 'remote' source is actually
  # this same repository.
  # Terraform performs a git clone operation to retrieve thise remote source,
  # so we use depth=1 to prevent unnecessary commit history cloning. 
  # We use tags in our repository to mark module versions, and select these versions
  # using the ref parameter. This way, we can test changes to the modules in our 
  # staging environment by selecting a different version, without affecting our
  # production environment. 
  source  = "github.com/vhof/terraform-practice//chapter-04/modules/data-stores/mysql?depth=1&ref=v0.0.1"
  stadium = local.stadium
  
  instance_type = "db.t3.micro"

  db_username = var.db_username
  db_password = var.db_password
}