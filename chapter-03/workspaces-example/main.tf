provider "aws" {}

terraform {
  backend "s3" {
    key = "workspaces-example/terraform.tfstate"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-073130f74f5ffb161"
  instance_type = terraform.workspace == "default" ? "t3.small" : "t3.micro"
}
