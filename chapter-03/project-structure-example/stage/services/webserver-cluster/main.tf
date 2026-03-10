provider "aws" {}

terraform {
  backend "s3" {
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}

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

resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

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

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# launch_template instead of launch_configuration, because the latter is not available
# to the Free account tier
resource "aws_launch_template" "example" {
  name_prefix            = "example"
  image_id               = "ami-073130f74f5ffb161"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(
    templatefile("user-data.sh", {
      server_port = var.server_port
      db_address  = data.terraform_remote_state.db.outputs.address
      db_port     = data.terraform_remote_state.db.outputs.port
    })
  )
}

resource "aws_autoscaling_group" "example" {
  launch_template { id = aws_launch_template.example.id }
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 5

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

