variable "bucket" {
  description = "Name of the AWS S3 bucket storing the Terraform state"
  type        = string
}

variable "stadium" {
  description = "Application stadium (e.g. \"dev\", \"stage\" or \"prod\")"
  type        = string
}

# REPLACED BY LOCALLY COMPUTING NAME BASED ON var.stadium
# variable "cluster_name" {
#   description = "The name to use for all the cluster resources"
#   type        = string
# }

# REPLACED BY ENVIRONMENT VARIABLE
# variable "db_remote_state_bucket" {
#   description = "The name of the S3 bucket for the database's remote state"
#   type        = string
# }

# REPLACED BY LOCALLY COMPUTING NAME BASED ON var.stadium
# variable "db_remote_state_key" {
#   description = "The path for the database's remote state in S3"
#   type        = string
# }

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t3.micro)"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}
