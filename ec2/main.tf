terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }

  }
  required_version = "~> 1.3"
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_ebs_volume" "example" {
  availability_zone = "us-east-1a"
  size              = 12
  type              = "gp3"
  tags = {
    Name = "ebs1",
    Env  = "PROD"
  }
}

data "aws_key_pair" "example" {
  key_name = "debian-ssh-public-key"
  #   include_public_key = true

  #   filter {
  #     name   = "tag:Component"
  #     values = ["web"]
  #   }
}

resource "aws_instance" "web" {
  ami                         = "ami-07caf09b362be10b8"
  instance_type               = "t3.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  key_name                    = data.aws_key_pair.example.key_name

  tags = {
    Name = "HelloWorld2"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdx"
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.web.id
}
