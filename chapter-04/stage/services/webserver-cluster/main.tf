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
  # Terraform supports retrieving modules from remote sources. 
  # Conventionally, our modules should live in a seperate repository,
  # but I didn't feel like doing that. So, this 'remote' source is actually
  # this same repository.
  # Terraform performs a git clone operation to retrieve this remote source,
  # so we use depth=1 to prevent unnecessary commit history cloning. 
  # We use tags in our repository to mark module versions, and select these versions
  # using the ref parameter. This way, we can test changes to the modules in our 
  # staging environment by selecting a different version, without affecting our
  # production environment. 
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
