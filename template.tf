# Provider configuration
provider "aws" {
  region = "us-east-2"
}

# Network configuration
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.my_vpc.id}"
    cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow ssh traffic"
  vpc_id = "${aws_vpc.my_vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["96.8.80.0/20"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Resource configuration
resource "aws_instance" "master-instance" {
      ami = "ami-c55673a0"
      instance_type = "t2.micro"
      subnet_id = "${aws_subnet.public.id}"
      vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
    }
    resource "aws_instance" "slave-instance" {
      ami = "ami-c55673a0"
      instance_type = "t2.micro"
      subnet_id = "${aws_subnet.public.id}"
      depends_on = ["aws_instance.master-instance"]
      vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
    }
