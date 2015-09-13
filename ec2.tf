/* */
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region"     { default = "ap-southeast-1" }
variable "vpc_subnet_zone_white" { default = "b" }
variable "cluster_name" { default = "my-dev-cluster" }
variable "cidr_home" {}

provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region     = "${var.aws_region}"
}

module "vpc" {
    source = "github.com/tmtk75/terraform-modules/aws/vpc"
    region = "${var.aws_region}"
    subnet_zone_white = "${var.vpc_subnet_zone_white}"
    vpc_name = "${var.cluster_name}"
}

module "ami-centos" {
    source = "github.com/tmtk75/terraform-modules/aws/ami"
    distribution        = "centos"
    version             = "7"
    region              = "ap-southeast-1"
    virtualization_type = "hvm"
}

resource "aws_key_pair" "ec2-key" {
    key_name   = "${var.cluster_name}"
    public_key = "${file("id_rsa.pub")}"
}

resource "aws_security_group" "common" {
    name        = "common"
    description = "common"
    vpc_id      = "${module.vpc.vpc_id}"
    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        self      = true
    }
    egress {
         from_port   = 0
         to_port     = 0
         protocol    = "-1"
         cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 8300  # consul Server RPC
        to_port   = 8300
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 8301  # consul Serf LAN
        to_port   = 8301
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 8301  # consul Serf LAN
        to_port   = 8301
        protocol  = "udp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 8302  # consul Serf WAN
        to_port   = 8302
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 8302  # consul Serf WAN
        to_port   = 8302
        protocol  = "udp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 8400  # consul CLI RPC
        to_port   = 8400
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 8500  # consul HTTP API
        to_port   = 8500
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 8600  # consul DNS Interface
        to_port   = 8600
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 8600  # consul DNS Interface
        to_port   = 8600
        protocol  = "udp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 9200  # elasticsearch
        to_port   = 9200
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    tags = {
        Name = "${var.cluster_name}"
    }
}

resource "aws_instance" "node" {
    ami             = "${module.ami-centos.ami_id}"
    instance_type   = "t2.micro"
    key_name        = "${aws_key_pair.ec2-key.key_name}"
    security_groups = ["${aws_security_group.common.id}"]
    subnet_id       = "${module.vpc.subnet_id_black}"
    associate_public_ip_address = true
    disable_api_termination     = false
    count = 6

    root_block_device {
        volume_size = 20
    }
    ephemeral_block_device {
        device_name = "/dev/sdb"
        virtual_name = "ephemeral0"
    }
    tags {
        Name = "${var.cluster_name}.${count.index}"
    }
}

output aws_region        { value = "${var.aws_region}" }
output node0             { value = "${aws_instance.node.0.public_dns}" }
output node1             { value = "${aws_instance.node.1.public_dns}" }
output node2             { value = "${aws_instance.node.2.public_dns}" }
output node3             { value = "${aws_instance.node.3.public_dns}" }
output node4             { value = "${aws_instance.node.4.public_dns}" }
output node5             { value = "${aws_instance.node.5.public_dns}" }
output node0.private_dns { value = "${aws_instance.node.0.private_dns}" }
output node1.private_dns { value = "${aws_instance.node.1.private_dns}" }
output node2.private_dns { value = "${aws_instance.node.2.private_dns}" }
output node3.private_dns { value = "${aws_instance.node.3.private_dns}" }
output node4.private_dns { value = "${aws_instance.node.4.private_dns}" }
output node5.private_dns { value = "${aws_instance.node.5.private_dns}" }
