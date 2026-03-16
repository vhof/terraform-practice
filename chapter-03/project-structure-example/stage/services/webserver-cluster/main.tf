provider "aws" {
  # ALTERED: AWS_DEFAULT_REGION variable in environment
  # region = eu-north-1
}

## The top-level "terraform" block allows us to configure Terraform behavior, 
## such as version, backend.

# In this case, we configure a remote backend state store in an s3 bucket.
# To collaborate on Terraform configurations, sharing a state file is required. 
# An s3 bucket is essentially AWS cloud storage. The key indicates the filepath.
# For clarity, we mirror the path to this Terraform configuration in our project. 
# Terraform backend configurations are limited in that they cannot refer to 
# named values (like input variables, locals, or data source attributes).
# To follow DRY principles, we can use a seperate backend configuration file.
terraform {
  backend "s3" {
    key = "stage/services/webserver-cluster/terraform.tfstate"

    # ALTERED: The following values are stored in a backend-config file, 
    # which should be  included when calling <terraform init> on the 
    # command line. 

    # The name of the bucket has to be unique across all of AWS

    # ALTERED: S3 buckets now support file locking inherently. 
    # I'm using this instead of a seperate DynamoDB lock table, such as in the
    # book. File locking on the state file is necessary to prevent conflicts. 

    # S3 buckets support file encryption at rest, which we turned on in our
    # configuration. This setting instructs Terraform to encrypt the state
    # file as well, adding an extra layer of security. 

    # bucket       = "terraform-up-and-running-state-vhof"
    # use_lockfile = true 
    # encrypt      = true
  }
}

# ALTERED: as suggested in the book, data sources have been moved to dependencies.tf

# This security group defines routing rules for our webserver instances.
# Allow inbound requests from within our VPC.
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  # Only allow inboud requests from within the VPC (ie, the load balancer)
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
}

# This security group defines routing rules for our Load Balancer.
# Allow all requests on the standard http port (80). 
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"

  # Use default subnets
  subnets         = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

# Listerner listens on standard HTTP port (80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
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

# The Target group for our webserver instances. 
# Performs health checks every 15 seconds. 
resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15 # Seconds between health checks. Range 5-300
    timeout             = 3  # Seconds of no response until failed health check. Range 2–120
    healthy_threshold   = 2  # Consecutive health check successes to consider target healthy. Range 2-10
    unhealthy_threshold = 2  # Consecutive health check failures to consider target unhealthy. Range 2-10
  }
}

# Listener rule. Forwards all request path patterns
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    target_group_arn = aws_lb_target_group.asg.arn
    type             = "forward"
  }
}

# Changed from chapter-02 (moved and changed launch script)
# ALTERED: launch_template instead of launch_configuration.
# Individual webserver (EC2) instances
resource "aws_launch_template" "example" {
  name_prefix            = "example"
  image_id               = "ami-073130f74f5ffb161"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  # To improve code clarity, we move the launch script to a seperate file. 
  # we can still use Terraform string interpolation in that file, and we 
  # provide the values through the templatefile() function, which takes
  # a path string and the values as an object. 
  # In chapter-03, we've added a database. This is a seperate Terraform 
  # configuration. This configuration only know the IP address and port 
  # AFTER this configuration has been deployed on AWS. Because of this, these 
  # values come from a data source, in this case a terraform_remote_state. 
  # For demonstration, we display these values on our webpage. 
  user_data = base64encode(
    templatefile("user-data.sh", {
      server_port = var.server_port
      db_address  = data.terraform_remote_state.db.outputs.address
      db_port     = data.terraform_remote_state.db.outputs.port
    })
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  launch_template { id = aws_launch_template.example.id }
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 5

  tag {
    # Special AWS resource tag. Will become displayname in 
    # dashboard overviews. Case-sensitive 
    key                 = "Name" 
    value               = "terraform-asg-example"

    # propagate this tag to the instances at launch
    propagate_at_launch = true 
  }
}

# Changed from chapter-02: outputs have been moved to outputs.tf
