variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080
    validation {
      condition = 1024 <= var.server_port && var.server_port <= 65535
      error_message = "server_port must be a valid non-root port in the range 1024-65535"
    }
}

provider "aws" {
    region = "eu-north-1"
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "example" {
    ami = "ami-073130f74f5ffb161"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    user_data_replace_on_change = true

    tags = {
        Name = "terraform-example"
    }
}

output "public_ip" {
    value = aws_instance.example.public_ip
    description = "The public IP address of the web server"
}