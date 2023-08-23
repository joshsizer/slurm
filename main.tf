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

resource "aws_instance" "slurm_control" {
  ami           = "ami-08a52ddb321b32a8c"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.slurm_subnet_us_east_1a.id
  security_groups = ["${aws_security_group.slurm_ssh.id}"]

  tags = {
    Name = "slurm-controller"
  }
}

resource "aws_vpc" "slurm_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "slurm_vpc"
  }
}

resource "aws_subnet" "slurm_subnet_us_east_1a" {
  vpc_id            = aws_vpc.slurm_vpc.id
  cidr_block        = "10.0.0.0/16"
  availability_zone = "us-east-1a"

  tags = {
    Name = "slurm_subnet_us_east_1a"
  }
}

resource "aws_internet_gateway" "slurm_internet_gateway" {
  vpc_id = "${aws_vpc.slurm_vpc.id}"
  
  tags = {
    Name = "slurm_internet_gateway"
  }
}

resource "aws_route_table" "slurm_route_table" {
  vpc_id = "${aws_vpc.slurm_vpc.id}"
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.slurm_internet_gateway.id}"
  }

  tags {
    Name = "slurm_route_table"
  }
}

resource "aws_eip" "slurm_controller_eip" {
  instance = "${aws_instance.slurm_control.id}"
  domain   = "vpc"

  tags = {
    Name = "slurm_controller_eip"
  }
}

resource "aws_security_group" "slurm_ssh" {
  name        = "slurm_ssh"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.slurm_vpc.id

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
  }
}
