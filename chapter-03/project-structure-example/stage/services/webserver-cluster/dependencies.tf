# Unchanged from chapter-02
# Default AWS Virtual Private Network
data "aws_vpc" "default" {
  default = true
}

# Unchanged from chapter-02
# Default AWS VPS default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# This data source is the (remote) state file of our database.
# This database is deployed by a different Terraform configuration,
# (data-stores/mysql). We need this data source to retrieve the 
# IP and port of the database. 
# We can derive the key from the module path. 
# The bucket is the same bucket we use to store the state of this configuration.
# By using the backend-configuration file as a var-file input as well, I
# can reuse that definition to get a bucket variable in this configuration. 
# In contrast to backend configurations, a Terraform remote state data source
# CAN use variable references. 
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    key    = "stage/data-stores/mysql/terraform.tfstate"
    bucket = var.bucket
    # region = AWS_DEFAULT_REGION (environment)
  }
}
