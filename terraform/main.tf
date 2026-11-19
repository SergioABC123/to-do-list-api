terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  cloud {
    organization = "todo-list-api"

    workspaces {
      name = "todo-list-api"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "api" {
  name        = "todo-list-api"
  description = "Controla el trafico de la API de tareas"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "api" {
  security_group_id = aws_security_group.api.id
  cidr_ipv4         = var.api_ingress_cidr
  ip_protocol       = "tcp"
  from_port         = 8000
  to_port           = 8000
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.api.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }
}

resource "aws_key_pair" "api" {
  key_name   = "todo-list-api"
  public_key = var.ec2_public_key
}

resource "aws_instance" "api" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.api.id]
  key_name                    = aws_key_pair.api.key_name

  tags = {
    Name = "todo-list-api"
  }

  iam_instance_profile = "LabInstanceProfile"

  user_data = templatefile("${path.module}/user_data.sh", {
    repository_url      = var.repository_url
    aws_region          = var.aws_region
    database_host       = aws_db_instance.tasks.address
    database_name       = aws_db_instance.tasks.db_name
    database_secret_arn = aws_db_instance.tasks.master_user_secret[0].secret_arn
  })
  user_data_replace_on_change = true
}