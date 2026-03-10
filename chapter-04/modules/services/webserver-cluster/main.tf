locals {
  cluster_name        = "webserver-${var.stadium}"
  db_remote_state_key = "${var.stadium}/data-stores/mysql/terraform.tfstate"

  image_id = "ami-073130f74f5ffb161"

  any_port      = 0
  instance_port = 8080
  http_port     = 80

  any_protocol  = "-1"
  tcp_protocol  = "tcp"
  http_protocol = "HTTP"

  all_ips = ["0.0.0.0/0"]

  page_not_found_response = {
    content_type = "text/plain"
    message_body = "404: oopsiewhoopsie no page here"
    status_code  = 404
  }
}

resource "aws_security_group" "instance" {
  name_prefix = "terraform-example-instance"

}

# Only allow inboud requests from within the VPC (ie, the load balancer)
resource "aws_security_group_rule" "allow_vpc_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = local.instance_port
  to_port     = local.instance_port
  protocol    = local.tcp_protocol
  cidr_blocks = [data.aws_vpc.default.cidr_block]
}

resource "aws_security_group" "alb" {
  name = "${local.cluster_name}-alb-sg"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_lb" "example" {
  name               = "${local.cluster_name}-asg-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = local.http_protocol

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = local.page_not_found_response.content_type
      message_body = local.page_not_found_response.message_body
      status_code  = local.page_not_found_response.status_code
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name     = "${local.cluster_name}-asg-tg"
  port     = local.instance_port
  protocol = local.http_protocol
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = local.http_protocol
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
  image_id               = local.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(
    templatefile("${path.module}/user-data.sh", {
      server_port = local.instance_port
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

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = "${local.cluster_name}-asg"
    propagate_at_launch = true
  }
}

