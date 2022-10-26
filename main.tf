module "vpc" {
  source = "cloudposse/vpc/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"

  namespace  = var.namespace
  name       = "vpc"
  stage      = var.stage
  cidr_block = var.cidr_block
}

locals {
  public_cidr_block  = cidrsubnet(module.vpc.vpc_cidr_block, 1, 0)
  private_cidr_block = cidrsubnet(module.vpc.vpc_cidr_block, 1, 1)
}

module "public_subnets" {
  source = "cloudposse/multi-az-subnets/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"

  namespace           = var.namespace
  stage               = var.stage
  name                = var.name
  availability_zones  = ["us-east-1a", "us-east-1b"]
  vpc_id              = module.vpc.vpc_id
  cidr_block          = local.public_cidr_block
  type                = "public"
  igw_id              = module.vpc.igw_id
  nat_gateway_enabled = "true"
}

module "private_subnets" {
  source = "cloudposse/multi-az-subnets/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"

  namespace           = var.namespace
  stage               = var.stage
  name                = var.name
  availability_zones  = ["us-east-1a", "us-east-1b"]
  vpc_id              = module.vpc.vpc_id
  cidr_block          = local.private_cidr_block
  type                = "private"
  az_ngw_ids          = module.public_subnets.az_ngw_ids
}


resource "aws_security_group" "dev-vpc-sg" {
  name = "dev-vpc-default-sg"
  vpc_id = module.vpc.vpc_id
  description = "Dev VPC Default Security Group"

  ingress {
    description = "Allow Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_instance" "my-ec2-vm" {
  ami = "ami-0be2609ba883822ec" # Amazon Linux
  instance_type = "t2.micro"
  subnet_id = module.private_subnets.az_subnet_ids["us-east-1a"]
  key_name = "tf_cloud_kp"
	#user_data = file("apache-install.sh")
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "<h1>Welcome to  AWS Infra created using Terraform in us-east-1 Region</h1>" > /var/www/html/index.html
    EOF  
  vpc_security_group_ids = [ aws_security_group.dev-vpc-sg.id ]
}


resource "aws_instance" "my-ec2-vm2" {
  ami = "ami-0be2609ba883822ec" # Amazon Linux
  instance_type = "t2.micro"
  subnet_id = module.private_subnets.az_subnet_ids["us-east-1b"]
  key_name = "tf_cloud_kp"
	#user_data = file("apache-install.sh")
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "<h1>Welcome to AWS Infra created using Terraform in us-east-1 Region</h1>" > /var/www/html/index.html
    EOF  
  vpc_security_group_ids = [ aws_security_group.dev-vpc-sg.id ]
}


output "private_az_subnet_ids" {
  value = module.private_subnets.az_subnet_ids
}

output "public_az_subnet_ids" {
  value = module.public_subnets.az_subnet_ids
}

output "vpc_ids" {
  value = module.vpc.vpc_id
}