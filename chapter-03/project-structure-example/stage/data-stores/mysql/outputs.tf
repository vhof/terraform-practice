# Output IP address for connecting to the database
output "address" {
  value       = aws_db_instance.example.address
  description = "Connect to the database at this endpoint"
}

# Output port for connecting to the database
output "port" {
  value       = aws_db_instance.example.port
  description = "The port the database is listening on"
}
