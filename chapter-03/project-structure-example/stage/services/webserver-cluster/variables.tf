variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
  validation {
    condition     = 1024 <= var.server_port && var.server_port <= 65535
    error_message = "server_port must be a valid non-root port in the range 1024-65535"
  }
}