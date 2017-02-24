# Provider configuration
provider "aws" {
  region = "${var.region}"
}

# Network configuration
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
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

module "IfYouStrayDownThatWay" {
  source = "./modules/application"
  vpc_id = "${aws_vpc.my_vpc.id}"
  subnet_id = "${aws_subnet.public.id}"
  name = "Stray"
  environment = "${var.environment}"
  extra_sgs = ["${aws_security_group.default.id}"]
}

module "BalmyBreezes" {
  source = "./modules/application"
  vpc_id = "${aws_vpc.my_vpc.id}"
  subnet_id = "${aws_subnet.public.id}"
  name = "Balmy_Breezes ${module.IfYouStrayDownThatWay.hostname}"
  environment = "${var.environment}"
  extra_sgs = ["${aws_security_group.default.id}"]
}
