variable "region" {
  description = "Choose a default region"
  type        = string
  default     = "us-east-1"
}


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


variable "web_amis" {
  type = map(any)
  default = {
    us-east-1 = "ami-0c02fb55956c7d316"
    us-east-2 = "ami-0421decc121d5f462"
  }
}


variable "web_tags" {
  description = "Choose tags for web ec2"
  type        = map(any)
  default = {
    Name = "webserver"
  }
}


#####################
# Network variables
#####################

variable "vpc_cidr_block" {
  description = "Choose cidr_block for vpc"
  type        = string
  default     = "10.30.0.0/16"
}