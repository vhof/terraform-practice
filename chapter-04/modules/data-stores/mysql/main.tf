locals {
  db_name = "mysql_db_${var.stadium}"
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = var.instance_type
  db_name             = local.db_name
  skip_final_snapshot = true # For learning. Destroy fails otherwise.

  username = var.db_username
  password = var.db_password
}
