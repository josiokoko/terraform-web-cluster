output "alb_dns_name" {
  value       = aws_lb.web_cluster.dns_name
  description = "The domain name of the load balancer"
}