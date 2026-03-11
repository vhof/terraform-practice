## "provider" informs Terraform which API calls to use and what kind of resources are available
provider "aws" {
  region = "eu-north-1"
}


## "data" sources are external read-only objects. We need these information sources
## for our infrastructure configurations, but cannot know them beforehand
## The arguments you pass in are typically search filters that
## indicate to the data source what information you’re looking for.

# "VPC" (Virtual Private Cloud) is essentially amazon's VPN structure
# It "is an isolated area of your AWS account that has its own virtual network and IP
# address space. Just about every AWS resource deploys into a VPC" (Brikman, 2022)
data "aws_vpc" "default" {
  default = true
}

# VPC's are partitioned into subnets. These are public by default. 
# We need this data source for our Auto-Scaling Group
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


## "variables" are input variables for your configuration. 
## It can have type and other validation constraints, and a default value. 
## A variable can also be marked as sensitive, which will hide it from
## the command line preview and planning outputs. 
## Terraform will look for a value in the following order:
## 1. Any -var and -var-file options on the command line in the order provided and variables from HCP Terraform
## 2. Any *.auto.tfvars or *.auto.tfvars.json files in lexical order
## 3. The terraform.tfvars.json file
## 4. The terraform.tfvars file
## 5. Environment variables
## 6. The default argument of the variable block
variable "server_port" {
  # particularly the individual webserver instances
  description = "The port the webserver will use for HTTP requests"
  type        = number
  default     = 8080
  validation {
    # listening on any port less than 1024 requires root user privileges
    # running a web server with root user priviliges is a security risk
    # Our Load Balancer will listen on port 80, but our webserver instances
    # won't. 
    condition     = 1024 <= var.server_port && var.server_port <= 65535
    error_message = "server_port must be a valid non-root port in the range 1024-65535"
  }
}


## "resources" are the actual components of an infrastructure, 
## e.g. routing tables, webservers, databases

# This security group defines routing rules for our webserver instances.
# By default, AWS does not allow any incoming or outgoing traffic from an EC2 Instance.
# We will allow inbound requests from within our VPC.
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  # Only allow inboud requests from within the VPC (ie, the Load Balancer)
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block] # the IP addresses within the (default) VPC
  }
}

# This security group defines routing rules for our Load Balancer.
# By default, AWS does not allow any incoming or outgoing traffic on any recourse, 
# including load balancers.
# The Load Balancer stands at the public facing 'entrance' to our website, 
# so we allow all requests on the standard http port (80). 
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # All IPv4 addresses
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # All IPv4 addresses
  }
}

# The Load Balancer(s), or AWS ELB (Elastic Load Balancer). There are 3 types:
#
# Application (ALB), best for HTTP traffic (application layer)
# Network (NLB), best for TCP, UDP, and TLS traffic, far faster than ALB (transport layer)
# Classic (CLB), legacy. Handles TCP and TLS, but with fewer features (application and transport layers)
#
# We use an ALB, as it's more that capable enough for a static website
# An ALB consists of Listeners, Listener rules, and Target groups
#
# Listeners receive the requests
# Listener rules govern to which Target groups the requests get sent
# Target groups govern the server instances and perform health checks,
# flagging and blocking traffic to unhealthy instances
#
# "AWS load balancers don’t consist of a single server, but of multiple servers that 
# can run in separate subnets (and, therefore, separate datacenters). AWS automatically 
# scales the number of Load Balancer servers up and down based on traffic and handles 
# failover if one of those servers goes down, so you get scalability and high 
# availability out of the box" (Brikman, 2022)
resource "aws_lb" "example" {
  name               = "terraform-lb-example"
  load_balancer_type = "application"

  # which subnets to use
  subnets = data.aws_subnets.default.ids

  # the routing rules
  security_groups = [aws_security_group.alb.id]
}

# The Listener configures how/where the Load Balancer listens to requests.
# Also sets a default response to faulty requests
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn # The Load Balancer that this Listener is part of. ARN = Amazon Resource Name
  port              = 80                 # standard HTTP port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: oopsiewhoopsie no page here"
      status_code  = 404
    }
  }
}

# The Target group for our webserver instances. Performs health checks using
# HTTP requests every 15 seconds
# A Targat group can be a static list of instances, but we use an Auto Scaling Group (ASG)
resource "aws_lb_target_group" "asg" {
  name     = "terraform-lb-target_group-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id # The VPC where the instances live

  health_check {
    path                = "/" # Destination for health check requests. Required for HTTP/HTTPS ALB. Default is "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15 # Seconds between health checks. Range 5-300
    timeout             = 3  # Seconds of no response until failed health check. Range 2–120
    healthy_threshold   = 2  # Consecutive health check successes to consider target healthy. Range 2-10
    unhealthy_threshold = 2  # Consecutive health check failures to consider target unhealthy. Range 2-10
  }
}

# A Listener rule 'matches' the request received by a Listener to the 
# correct Target group according to the path_pattern. 
# Our Listener rule forwards all request path patterns
resource "aws_lb_listener_rule" "asg" {
  # Our Listener
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"] # all patterns
    }
  }

  action {
    # Our Target group
    target_group_arn = aws_lb_target_group.asg.arn
    type             = "forward"
  }
}

# ALTERED: launch_template instead of launch_configuration, because the latter is not available
# to the Free account tier
# This is the configuration for the individual webserver (EC2) instances
resource "aws_launch_template" "example" {
  name_prefix            = "example"
  image_id               = "ami-073130f74f5ffb161" # Amazon Machin Image id. This is a Ubuntu Server 24.04 LTS (HVM) image
  instance_type          = "t3.micro"              # Informs CPU and Memory capacity and such (and pricing)
  vpc_security_group_ids = [aws_security_group.instance.id]

  # Instance launch script. 
  # <<-EOF allows for multiline strings preserving indentation.
  # <<EOF does the same without indentation.
  # Launch templates require base64 encoded user_data.
  # String interpolation is done using ${...}
  # Launches a simple busybox webserver in the background
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  )
}

# An Auto Scaling Group (ASG) automatically ensures some amount of running
# and healthy EC2 instances, scaling up in response to load and deploying
# new instances if old ones fail. 
# Instance health is decided by the Target group. Our Target group is essentially
# a wrapper around our ASG
resource "aws_autoscaling_group" "example" {
  launch_template { id = aws_launch_template.example.id } # instance configuration
  vpc_zone_identifier = data.aws_subnets.default.ids      # subnets to use

  target_group_arns = [aws_lb_target_group.asg.arn] # the Target group this ASG is part of

  # Instructs the ASG to use the Target group’s health check to determine Instance health
  health_check_type = "ELB" # Elastic Load Balancer

  min_size = 2 # Minimum number of instances
  max_size = 5 # Maximum number of instances

  tag {
    key                 = "Name" # Special AWS resource tag. Will become displayname in dashboard overviews. Case-sensitive 
    value               = "terraform-asg-example"
    propagate_at_launch = true # propagate this tag to the instances at launch
  }
}


## "outputs" are Terraform output variables. They are displayed on the command line
## or can be accessed by other Terraform configurations using this module. 

output "public_dns" {
  value       = aws_lb.example.dns_name
  description = "The DNS of the Load Balancer"
}
