provider "aws" {}

terraform {
  backend "s3" {
    key = "prod/services/webserver-cluster/terraform.tfstate"
  }
}

locals {
  stadium = "prod"

  min_size = 2
  max_size = 10
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
  # cluster_name        = "webserver-prod"
  # db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"

  instance_type = "t3.micro"
  min_size      = local.min_size
  max_size      = local.max_size
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name  = "scale-out-during-business-hours"
  autoscaling_group_name = module.webserver_cluster.asg_name

  min_size         = local.min_size
  max_size         = local.max_size
  desired_capacity = local.max_size
  recurrence       = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name  = "scale-in-at-night"
  autoscaling_group_name = module.webserver_cluster.asg_name

  min_size         = local.min_size
  max_size         = local.max_size
  desired_capacity = local.min_size
  recurrence       = "0 17 * * *"
}
