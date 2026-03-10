variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "stadium" {
  description = "Application stadium (e.g. \"dev\", \"stage\" or \"prod\")"
  type        = string
}

variable "instance_type" {
  description = "The type of RDS Instances to run (e.g. db.t3.micro)"
  type        = string
}