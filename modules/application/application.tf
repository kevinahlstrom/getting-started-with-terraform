variable "vpc_id"    {}
variable "subnet_id" {}
variable "name"      {}

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

#pull most recently created AMI from the AWS account used for Terraform runs
data "aws_ami" "app-ami" {
  most_recent = true
  owners = ["self"]
}



# generate random hostname
resource "random_id" "hostname" {
  # if a new AMI is there, then the instance will be recreated and new hostname is required
  keepers {
    ami_id = "${data.aws_ami.app-ami.id}"
  }
  byte_length = 4
}
# template data file resource
data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.sh.tpl")}"

  vars {
    packages = "${var.extra_packages}"
    nameserver = "${var.external_nameserver}"
    hostname = "${random_id.hostname.b64}"
  }
}

# Resource configuration
resource "aws_instance" "master-instance" {
      ami = "${data.aws_ami.app-ami.id}"
      instance_type = "${lookup(var.instance_type, var.environment)}"
      subnet_id = "${var.subnet_id}"

      # join the extra_sgs list in template.tf with the list made from this app-specific SG defined in application.tf
      # / remove any duplicates with distinct
      vpc_security_group_ids = ["${distinct(concat(var.extra_sgs, aws_security_group.allow_http.*.id))}"]

      #render this template file as a user data for the instance
      user_data = "${data.template_file.user_data.rendered}"

      #tell the instance to ignore changes of user_data to avoid instance re-creation every time file is touched
      lifecycle {
        ignore_changes = ["user_data"]
      }

      tags {
        Name = "${var.name}"
      }
    }
    resource "aws_instance" "slave-instance" {
      ami = "${data.aws_ami.app-ami.id}"
      instance_type = "${lookup(var.instance_type, var.environment)}"
      subnet_id = "${var.subnet_id}"
      depends_on = ["aws_instance.master-instance"]

      # join the extra_sgs list in template.tf with the list made from this app-specific SG defined in application.tf
      # / remove any duplicates with distinct
      vpc_security_group_ids = ["${distinct(concat(var.extra_sgs, aws_security_group.allow_http.*.id))}"]

      #render this template file as a user data for the instance
      user_data = "${data.template_file.user_data.rendered}"

      #tell the instance to ignore changes of user_data to avoid instance re-creation every time file is touched
      lifecycle {
        ignore_changes = ["user_data"]
      }

      tags {
        Name = "${var.name}"
      }
    }

    output "hostname" {
      value = "${aws_instance.master-instance.private_dns}"
      value = "${aws_instance.slave-instance.private_dns}"
    }
