terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
     
    
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
   access_key = "kkkkkkkkkkkkkkkkkkkkkk"
   secret_key = "rrrrrrrrrrrrrrrrrrFrf"
}

# resource "aws_instance" "my-first-server" {
#   ami           = "ami-00ddb0e5626798373"
#   instance_type = "t2.micro"

#   }

#   resource "aws_instance" "my-second-server" {
#   ami           = "ami-00ddb0e5626798373"
#   instance_type = "t2.micro"

#   }

# resource "aws_vpc" "main" {
#   cidr_block       = "10.0.0.0/16"
#   instance_tenancy = "default"

#   tags = {
#     Name = "main"
#   }
# }

resource "aws_vpc" "first_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
      Name = "production"
  }

}



resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet"
  }
}