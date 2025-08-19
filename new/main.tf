terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.19.0" # Specify a compatible version
    }
  }

  backend "s3" {
    bucket = "briankpleung-terraform-state"
    key = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1" # Example region
}

resource "aws_s3_bucket" "my_bucket" {
  bucket  = "c5034218-xxx"
  tags    = {
	Name          = "MyS3Bucket"
	Environment    = "Production"
  }
}

