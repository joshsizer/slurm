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
