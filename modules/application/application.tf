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

# will return a randomly ordered list of items from the original list you provide.
# Can be used with the hostname generator below
resource "random_shuffle" "hostname_creature" {
  input = ["griffin", "gargoyle", "dragon"]
  result_count = 1
}

# generate both private and public key that could be used to get the initial SSH connection to the server
resource "tls_private_key" "example" {
    algorithm = "ECDSA"
    ecdsa_curve = "P384"
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
    hostname = "${random_shuffle.hostname_creature.result[0]}${random_id.hostname.b64}"
  }
}

# Small example of using consul_keys to set the AMI instead of using data source for AMI
provider "consul" {
    address = "consul.example.com:80"
    datacenter = "frankfurt"
}
data "consul_keys" "amis" {
    # Read the launch AMI from Consul
    key {
        name = "whatever_app"
        path = "ami"
    }
}
# Resource configuration
resource "aws_instance" "master-instance" {
      ami = "${consul_keys.amis.var.whatever_app}"
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
      ami = "${consul_keys.amis.var.whatever_app}"
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
