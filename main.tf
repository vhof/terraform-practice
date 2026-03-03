provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "example" {
    ami = "ami-073130f74f5ffb161"
    instance_type = "t3.micro"

    tags = {
        Name = "terraform-example"
    }
}