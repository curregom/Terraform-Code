#terraform init

#add provider

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider

provider "aws" {
  region = "us-east-1"
  access_key = "kkkkkkkkkkkkkkkkkkkkkkk"
   secret_key = "ssssssssssssssssssssssssssss"
}







# 1. create VPC

variable "subnet_prefix"{

  description = "cidr block for the subnet"
  # default = "10.0.66.0/24"
  # type = string
  
}

resource "aws_vpc" "prod-vpc" { //prod-vpc is the recource's name
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "production"
  }
}

# 2. Create Internet Gateway


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  }
# 3. Create Custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id  ##change excuted

  route {
    cidr_block = "0.0.0.0/0" #default route
    gateway_id = aws_internet_gateway.gw.id #referencing gw resource
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id #referencing gw resource IPv6
  }

  tags = {
    Name = "Prod"
  }
}

# 4. Create a subnet

resource "aws_subnet" "subnet-1" {

  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[0].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  } 
}

resource "aws_subnet" "subnet-2" {

  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[1].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[1].name
  } 
}


# 5. Associate a Subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}


# 6. Create a Security Group to allow ports 22,80,443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a Network Interface with an IP in the Subnet that was Created in step 4

resource "aws_network_interface" "webserver-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  # attachment {
  #   instance     = aws_instance.test.id
  #   device_index = 1
  # }
}


# 8. Assign an Elastic IP to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webserver-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

# 9. Create an ubuntu server and install/enable apache 2 

resource "aws_instance" "web-server-instance"{
  ami = "ami-00ddb0e5626798373"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  network_interface{

    device_index = 0
    network_interface_id = aws_network_interface.webserver-nic.id
  } 

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first server > /var/www/html/index.html'
              EOF
    tags = {
      Name = "web-server"
    }
}

#conecting using ssh
#
#
# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ chmod 400 main-key.pem 
# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ ssh -i main
# main-key.pem        main_production.tf  
# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ ssh -i main-key.pem ubuntu@52.203.167.67
# The authenticity of host '52.203.167.67 (52.203.167.67)' can't be established.
# ECDSA key fingerprint is SHA256:FxGsZ4ViTqY23rxbA3jyIum0aV+s7BYrub6HirN9GtI.
# Are you sure you want to continue connecting (yes/no/[fingerprint])? 

#terraform destroy --auto-approve

#terraform state

# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ terraform state list
# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ terraform state show name_of_resource




#terraform output
output "server_public_ip" {
  value = aws_eip.one.public_ip


}

# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ terraform apply --auto-approve
# aws_vpc.prod-vpc: Refreshing state... [id=vpc-078d47fac23bd48db]
#...
# aws_instance.web-server-instance: Refreshing state... [id=i-090f8118183a5d789]

# Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

# Outputs:

# server_public_ip = 52.203.167.67
# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ 
output "server_private_ip"{
  value = aws_instance.web-server-instance.private_ip

}

output "server_id"{
value = aws_instance.web-server-instance.id

}
#terraform output command: shows the outputs
# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ terraform output
# server_id = i-090f8118183a5d789
# server_private_ip = 10.0.1.50
# server_public_ip = 52.203.167.67



#terraform refresh: refreshes output states without running a terrafor apply
# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ terraform refresh
# aws_vpc.prod-vpc: Refreshing state... [id=vpc-078d47fac23bd48db]
#...
# aws_eip.one: Refreshing state... [id=eipalloc-068401416204d408c]
# aws_instance.web-server-instance: Refreshing state... [id=i-090f8118183a5d789]

# Outputs:

# server_id = i-090f8118183a5d789
# server_private_ip = 10.0.1.50
# server_public_ip = 52.203.167.67
# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ 

#Target resource

# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ terraform destroy -target aws_instance.web-server-instance

# You are creating a plan with the -target option, which means that the result
# of this plan may not represent all of the changes requested by the current
# configuration.

# The -target option is not for routine use, and is provided only for
# exceptional situations such as recovering from errors or mistakes, or when
# Terraform specifically suggests to use it as part of an error message.

# carlos@DextersLab-ThinkPad:~/Documents/Terraform Projects/Practice_Project$ terraform apply -target aws_instance.web-server-instance

# Variables