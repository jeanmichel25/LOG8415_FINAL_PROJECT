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

# trusted host security group
resource "aws_security_group" "trusted_host_security_group" {
  name        = "trusted_host_security_group"
  vpc_id      = data.aws_vpc.default.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.88.10/32"] # gatekeeper ip, will only accept requests coming from gatekeeper
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.31.88.10/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# create 1 t2.micro standalone instance
resource "aws_instance" "t2_standalone" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.micro"
  user_data = file("standalone_data.sh") # used to run script which deploys docker container on each instance
  tags = {
    Name = "t2_standalone"
  }
}

# create 1 t2.micro manager instance
resource "aws_instance" "t2_manager" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.micro"
  availability_zone = "us-east-1d"
  user_data = file("manager_data.sh") # used to run script which deploys docker container on each instance
  private_ip = "172.31.88.0"
  key_name = "final_project_kp"
  tags = {
    Name = "manager"
  }
}

# create t2.micro worker instances
resource "aws_instance" "t2_worker1" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.micro"
  availability_zone = "us-east-1d"
  user_data = file("worker_data.sh") # used to run script which deploys docker container on each instance
  private_ip = "172.31.88.1"
  key_name = "final_project_kp"
  tags = {
    Name = "worker"
  }
}

resource "aws_instance" "t2_worker2" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.micro"
  availability_zone = "us-east-1d"
  user_data = file("worker_data.sh") # used to run script which deploys docker container on each instance
  private_ip = "172.31.88.2"
  key_name = "final_project_kp"
  tags = {
    Name = "worker"
  }
}

resource "aws_instance" "t2_worker3" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.micro"
  availability_zone = "us-east-1d"
  user_data = file("worker_data.sh") # used to run script which deploys docker container on each instance
  private_ip = "172.31.88.3"
  key_name = "final_project_kp"
  tags = {
    Name = "worker"
  }
}

# create 1 t2.large proxy instance
resource "aws_instance" "t2_proxy" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  instance_type = "t2.large"
  key_name = "final_project_kp"
  user_data = file("proxy_data.sh") # used to run script which deploys docker container on each instance
  tags = {
    Name = "proxy"
  }
}

# create 1 t2.large gatekeeper instance
resource "aws_instance" "t2_gatekeeper" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.final_security_group.id]
  availability_zone = "us-east-1d"
  instance_type = "t2.large"
  key_name = "final_project_kp"
  private_ip = "172.31.88.10"
  user_data = file("gatekeeper_data.sh") # used to run script which deploys docker container on each instance
  tags = {
    Name = "gatekeeper"
  }
}

# create 1 t2.large instance for the trusted host
resource "aws_instance" "t2_trusted_host" {
  count = 1
  ami = "ami-0fc5d935ebf8bc3bc"
  vpc_security_group_ids = [aws_security_group.trusted_host_security_group.id]
  instance_type = "t2.large"
  key_name = "final_project_kp"
  user_data = file("trusted_host_data.sh") # used to run script which deploys docker container on each instance
  tags = {
    Name = "trusted_host"
  }
}

output "proxy_public_ip" {
  value = aws_instance.t2_proxy[0].public_ip
}

output "gatekeeper_public_ip" {
  value = aws_instance.t2_gatekeeper[0].public_ip
}

output "manager_public_ip" {
  value = aws_instance.t2_manager[0].public_ip
}

output "worker1_public_ip" {
  value = aws_instance.t2_worker1[0].public_ip
}

output "worker2_public_ip" {
  value = aws_instance.t2_worker2[0].public_ip
}

output "worker3_public_ip" {
  value = aws_instance.t2_worker3[0].public_ip
}