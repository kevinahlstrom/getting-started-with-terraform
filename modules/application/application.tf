variable "vpc_id"    {}
variable "subnet_id" {}
variable "name"      {}

resource "aws_security_group" "allow_ssh" {
  name = "${var.name} allow_ssh"
  description = "Allow ssh traffic"
  vpc_id = "${var.vpc_id}"

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

resource "aws_security_group" "allow_http" {
  name = "${var.name} allow_http"
  description = "Allow http traffic"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
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
      instance_type = "${lookup(var.instance_type, var.environment)}"
      subnet_id = "${var.subnet_id}"
      vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
      tags {
        Name = "${var.name}"
      }
    }
    resource "aws_instance" "slave-instance" {
      ami = "ami-c55673a0"
      instance_type = "${lookup(var.instance_type, var.environment)}"
      subnet_id = "${var.subnet_id}"
      depends_on = ["aws_instance.master-instance"]
      vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
      tags {
        Name = "${var.name}"
      }
    }

    output "hostname" {
      value = "${aws_instance.master-instance.private_dns}"
      value = "${aws_instance.slave-instance.private_dns}"
    }
