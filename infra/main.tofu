terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  backend "s3" {
    bucket = "terraform-state-ezvacss"
    region = "eu-central-1"
    key    = "prod/terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "vm_count" {
  description = "number of vm to create"
  type        = number
  default     = 1
}

data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

locals {
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_subnet" "main" {
  vpc_id                 = aws_vpc.main.id
  cidr_block             = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

resource "aws_key_pair" "deployer" {
  key_name   = "my-first-key"
  public_key = file("~/.ssh/id_ed25519_awsCLI.pub")
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "web" {
  count                       = var.vm_count
  ami                         = data.aws_ami.debian.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "web-${count.index}"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh-http"
  description = "Allow SSH from my IP and HTTP from anywhere"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  ingress {
    description = "App from anywhere"
    from_port   = 8080
    to_port     = 8080
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
    Name = "allow-ssh-http"
  }
}

output "public_ips" {
  value = aws_instance.web[*].public_ip
}
