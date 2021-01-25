provider "aws" {
	region = "us-west-1"
}
# Create a VPC

resource "aws_vpc" "lab1" {
  cidr_block = "10.0.0.0/16"

}
# Creating subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.lab1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1b"
  tags = {
    Name = "Lab1"
  }
}
# Associating routing table with the subnet
resource "aws_route_table_association" "a" {
 subnet_id = aws_subnet.subnet-1.id
 route_table_id = aws_route_table.lab1-route-table.id
}
# Creating internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id     = aws_vpc.lab1.id
  tags = {
    Name = "Lab1"
  }
}
# creating route table
resource "aws_route_table" "lab1-route-table" {
  vpc_id = aws_vpc.lab1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Lab1"
  }
}
# creating security group with http allowed and ssh allowed from my ip
resource "aws_security_group" "sg1" {
  name        = "sg1-name"
  description = "Allow ssh and http"
  vpc_id      = aws_vpc.lab1.id
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["174.29.199.169/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Lab1"
  }
}
#creating key pair
resource "aws_key_pair" "gary_key" {
	key_name = "gary_key"
	public_key = file("gary_key.pub")
}
#Creating Network Interface
resource "aws_network_interface" "web-nic" {
 subnet_id = aws_subnet.subnet-1.id
 private_ips = ["10.0.1.50"]
 security_groups = [aws_security_group.sg1.id]
 }
#Creating Elastic IP
resource "aws_eip" "lab1_eip" { 
	vpc = true 
	network_interface = aws_network_interface.web-nic.id
	associate_with_private_ip = "10.0.1.50"
	depends_on = [aws_internet_gateway.gw]
}
resource "aws_instance" "web" {
  ami           = "ami-0a741b782c2c8632d"
  instance_type = "t2.micro"
  availability_zone = "us-west-1b"
  network_interface {
	device_index = 0
	network_interface_id = aws_network_interface.web-nic.id
  }
   key_name = "gary_key"
#   key_name = "gary1"
#  vpc_security_group_ids = [aws_security_group.sg1.id]
#  user_data = "file(./install.sh)"
   user_data = <<-EOF
		#!/bin/bash
		sudo apt update -y
		sudo apt install apache2 -y
		sudo systemctl start apache2
		sudo bash -c 'echo web server is ready > /var/www/html/index.html'
		EOF
}
output "IP" {
	value = [aws_instance.web.public_ip]
}
