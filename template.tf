# Provider configuration
provider "aws" {
  region = "${var.region}"
}

# Network configuration
#resource "aws_vpc" "my_vpc" {
#  cidr_block = "10.0.0.0/16"
#}
data "aws_vpc" "management_layer" {
  id = "vpc-2efe5547"
}

# external data example for Terraform templates
data "external" "example" {
  program = ["ruby", "${path.module}/convert_to_JSON.rb"]
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "${var.vpc_cidr}"
}

resource "aws_vpc_peering_connection" "my_vpc-management" {
  peer_vpc_id = "${data.aws_vpc.management_layer.id}"
  vpc_id = "${aws_vpc.my_vpc.id}"
  auto_accept = true
}

resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.my_vpc.id}"
    cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "default" {
  name = "Default SG"
  description = "Allow SSH access"
  vpc_id = "${aws_vpc.my_vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["96.8.80.0/20"]
  }
}

# import key pair
resource "aws_key_pair" "terraform" {
  key_name = "terraform"
  public_key = "${file("C:/Users/kahlstro/.ssh/id_rsa.pub")}"
}

module "IfYouStrayDownThatWay" {
  source = "./modules/application"
  vpc_id = "${aws_vpc.my_vpc.id}"
  subnet_id = "${aws_subnet.public.id}"
  #name = "Stray"
  name = "Stray-${data.external.example.result.owner}"
  environment = "${var.environment}"
  extra_sgs = ["${aws_security_group.default.id}"]
  extra_packages = "${lookup(var.extra_packages, "my_app", "base")}"
  external_nameserver = "${(var.external_nameserver)}"
}

module "BalmyBreezes" {
  source = "./modules/application"
  vpc_id = "${aws_vpc.my_vpc.id}"
  subnet_id = "${aws_subnet.public.id}"
  #name = "Balmy_Breezes ${module.IfYouStrayDownThatWay.hostname}"
  name = "Balmy_Breezes-${data.external.example.result.owner}"
  environment = "${var.environment}"
  extra_sgs = ["${aws_security_group.default.id}"]
  extra_packages = "${lookup(var.extra_packages, "my_app", "base")}"
  external_nameserver = "${(var.external_nameserver)}"
}
