terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# connect to aws
provider "aws" {
  region = "us-east-1"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  token = "${var.token}"
}

# create vpc
data "aws_vpc" "default" {
  default = true
}

# create security group
resource "aws_security_group" "final_security_group" {
  name        = "final_security_group"
  vpc_id      = data.aws_vpc.default.id
  
  # Define your security group rules here
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# # create 1 t2.micro standalone instance
# resource "aws_instance" "t2_standalone" {
#   count = 1
#   ami = "ami-0fc5d935ebf8bc3bc"
#   vpc_security_group_ids = [aws_security_group.final_security_group.id]
#   instance_type = "t2.micro"
#   user_data = file("standalone_data.sh") # used to run script which deploys docker container on each instance
#   tags = {
#     Name = "t2_standalone"
#   }
# }

# create 1 t2.micro manager instance
resource "aws_instance" "t2_manager" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.micro"
  user_data = file("manager_data.sh") # used to run script which deploys docker container on each instance
  private_ip = "172.31.85.0"
  tags = {
    Name = "t2_manager"
  }
}

# create t2.micro worker instances
resource "aws_instance" "t2_worker1" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.micro"
  user_data = file("worker_data.sh") # used to run script which deploys docker container on each instance
  private_ip = "172.31.85.1"
  tags = {
    Name = "t2_worker1"
  }
}

resource "aws_instance" "t2_worker2" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.micro"
  user_data = file("worker_data.sh") # used to run script which deploys docker container on each instance
  private_ip = "172.31.85.2"
  tags = {
    Name = "t2_worker2"
  }
}

resource "aws_instance" "t2_worker3" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.micro"
  user_data = file("worker_data.sh") # used to run script which deploys docker container on each instance
  private_ip = "172.31.85.3"
  tags = {
    Name = "t2_worker3"
  }
}

# # create 1 t2.large proxy instance
# resource "aws_instance" "t2_proxy" {
#   count = 1
#   ami = "ami-0fc5d935ebf8bc3bc"
#   vpc_security_group_ids = [aws_security_group.final_security_group.id]
#   instance_type = "t2.large"
#   user_data = file("proxy_data.sh") # used to run script which deploys docker container on each instance
#   tags = {
#     Name = "t2_proxy"
#   }
# }

# # create 1 t2.large gatekeeper instance
# resource "aws_instance" "t2_gatekeeper" {
#   count = 1
#   ami = "ami-0fc5d935ebf8bc3bc"
#   vpc_security_group_ids = [aws_security_group.final_security_group.id]
#   instance_type = "t2.large"
#   user_data = file("gatekeeper_data.sh") # used to run script which deploys docker container on each instance
#   tags = {
#     Name = "t2_gatekeeper"
#   }
# }
