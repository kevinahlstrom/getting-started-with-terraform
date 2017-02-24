variable "region" {
  description = "AWS region. Changing it will lead to loss of complete stack."
  default = "us-east-2"
}

variable "environment" { default = "dev" }

variable "allow_ssh_access" {
  description = "List of CIDR blocks that can access instances via SSH"
  default = ["96.8.80.0/20"] 
}
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "subnet_cidrs" {
  description = "CIDR blocks for public and private subnets"
  default = {
    public = "10.0.1.0/24"
    private = "10.0.2.0/24"
  }
}
