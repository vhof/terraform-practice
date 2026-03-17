provider "aws" {}

terraform {
  backend "s3" {
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}

locals {
  stadium = "stage"

  min_size = 2
  max_size = 2
}

module "webserver_cluster" {
  source  = "github.com/vhof/terraform-practice//chapter-04/modules/services/webserver-cluster?depth=1&ref=v0.0.1"
  bucket  = var.bucket
  stadium = local.stadium

  # ALTERED: following input variables are replaced by stadium, and values are
  # constructed inside of the modules
  # cluster_name        = "webserver-stage"
  # db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t3.micro"
  min_size      = local.min_size
  max_size      = local.max_size
}
