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

  tags = {
    Name = "slurm-control"
  }
}
