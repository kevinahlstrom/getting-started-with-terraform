variable "region" {
  description = "AWS region. Changing it will lead to loss of complete stack."
  default = "us-east-2"
}

variable "environment" {
  default = "dev"
}
