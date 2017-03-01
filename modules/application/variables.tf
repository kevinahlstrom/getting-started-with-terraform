variable "environment" { default = "dev" }

variable "instance_type" {
  type = "map"

  default = {
    dev = "t2.micro"
    test = "t2.medium"
    prod = "t2.large"
  }
}

#pass variables to the application module
variable "extra_sgs" { default = [] }
variable "extra_packages" {}
variable "external_nameserver" {} 
