output "public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Public IP address of the web server"
}