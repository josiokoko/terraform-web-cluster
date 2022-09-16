variable "server_port" {
  description = "Server port for http requests"
  type        = number
  default     = 80
}


variable "ec2_instance_type" {
  description = "Web ec2 instance type"
  type        = string
  default     = "t2.micro"
}