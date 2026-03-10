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
  source  = "../../../modules/services/webserver-cluster"
  bucket  = var.bucket
  stadium = local.stadium

  # REPLACED BY stadium
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
