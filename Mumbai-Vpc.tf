terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "mumbai" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Mumbai"
  }
}

resource "aws_subnet" "pubsubnet" {
  vpc_id     = aws_vpc.mumbai.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "PUB-SUB"
  }
}

resource "aws_subnet" "prtsubnet" {
  vpc_id     = aws_vpc.mumbai.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "PRT-SUB"
  }
}

resource "aws_internet_gateway" "pubgw" {
  vpc_id = aws_vpc.mumbai.id

  tags = {
    Name = "MY-IGW"
  }
}

resource "aws_route_table" "pubroutetable" {
  vpc_id = aws_vpc.mumbai.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pubgw.id
  }
 
  tags = {
    Name = "PUBRT"
  }
}

resource "aws_route_table_association" "pubrtass" {
  subnet_id      = aws_subnet.pubsubnet.id
  route_table_id = aws_route_table.pubroutetable.id
}

resource "aws_eip" "myeip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pubsubnet.id

  tags = {
    Name = "T-NAT"
  }
}

resource "aws_route_table" "prtroutetable" {
  vpc_id = aws_vpc.mumbai.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tnat.id
  }
 
  tags = {
    Name = "PrtRT"
  }
}

resource "aws_route_table_association" "prtrtass" {
  subnet_id      = aws_subnet.prtsubnet.id
  route_table_id = aws_route_table.prtroutetable.id
}

resource "aws_security_group" "pubsecgr" {
  name        = "allow_tls_pub"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.mumbai.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}

ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  tags = {
    Name = "PUB-S-G"
  }
}

resource "aws_security_group" "prtsecgr" {
  name        = "allow_tls_prt"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.mumbai.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}

ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  tags = {
    Name = "PRT-S-G"
  }
}

resource "aws_instance" "webapp" {
    ami                             = "ami-0327f51db613d7bd2"
    instance_type                   = "t2.micro"
    availability_zone               = "ap-south-1a"
    associate_public_ip_address     = "true"
    vpc_security_group_ids          = [aws_security_group.pubsecgr.id]
    subnet_id                       = aws_subnet.pubsubnet.id
    key_name                        = "th" 
  
}

resource "aws_instance" "dep" {
    ami                             = "ami-0327f51db613d7bd2"
    instance_type                   = "t2.micro"
    availability_zone               = "ap-south-1a"
    associate_public_ip_address     = "false"
    vpc_security_group_ids          = [aws_security_group.prtsecgr.id]
    subnet_id                       = aws_subnet.pubsubnet.id
    key_name                        = "th" 
}


