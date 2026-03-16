variable "db_username" {
  description = "The username for the database"
  type        = string

  # Prevents value from being visible in Terraform planning output
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}
