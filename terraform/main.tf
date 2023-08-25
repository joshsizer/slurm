terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.13.1"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_instance" "this" {
  ami           = "ami-07614bbb83bd07553"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.slurm_us_east_1a.id
  security_groups = ["${aws_security_group.ssh.id}"]
  key_name = aws_key_pair.slurm_controller_ssh.id

  tags = {
    Name = "slurm_controller"
  }
}

resource "aws_eip" "this" {
  instance = "${aws_instance.this.id}"
  domain   = "vpc"

  tags = {
    Name = "slurm_controller"
  }
}

resource "aws_key_pair" "slurm_controller_ssh" {
  public_key = "${var.slurm_controller_public_ssh_key}"

  tags = {
    Name = "slurm_controller_ssh"
  }
}

resource "aws_vpc" "this" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "slurm"
  }
}

resource "aws_subnet" "slurm_us_east_1a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = aws_vpc.this.cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = "slurm_us_east_1a"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"
  
  tags = {
    Name = "slurm"
  }
}

resource "aws_route_table" "this" {
  vpc_id = "${aws_vpc.this.id}"
  
  route {
    cidr_block = "${aws_vpc.this.cidr_block}"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.this.id}"
  }

  tags = {
    Name = "slurm"
  }
}

resource "aws_main_route_table_association" "this" {
  vpc_id         = aws_vpc.this.id
  route_table_id = aws_route_table.this.id
}

resource "aws_security_group" "ssh" {
  vpc_id      = aws_vpc.this.id

  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "slurm_ssh"
    Description = "Allow SSH traffic"
  }
}
