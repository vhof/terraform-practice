output "public_dns" {
  value       = aws_lb.example.dns_name
  description = "The DNS of the load balancer"
}