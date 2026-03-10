output "public_dns" {
  value       = module.webserver_cluster.public_dns
  description = "The DNS of the load balancer"
}