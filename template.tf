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

module "IfYouStrayDownThatWay" {
  source = "./modules/application"
  vpc_id = "${aws_vpc.my_vpc.id}"
  subnet_id = "${aws_subnet.public.id}"
  name = "Stray"
  environment = "${var.environment}"
}

module "BalmyBreezes" {
  source = "./modules/application"
  vpc_id = "${aws_vpc.my_vpc.id}"
  subnet_id = "${aws_subnet.public.id}"
  name = "Balmy_Breezes ${module.IfYouStrayDownThatWay.hostname}"
  environment = "${var.environment}"
}
