provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "test_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "test_vpc"
  }
}
resource "aws_subnet" "test_pub_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "test_pub_subnet"
  }
}
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name : "test_igw"
  }
}
resource "aws_route_table" "test_pub_rt" {
  vpc_id = aws_vpc.test_vpc.id
  route = [{
    carrier_gateway_id         = ""
    cidr_block                 = "0.0.0.0/0"
    destination_prefix_list_id = ""
    egress_only_gateway_id     = ""
    gateway_id                 = "aws_internet_gateway.test_igw.id"
    instance_id                = ""
    ipv6_cidr_block            = ""
    local_gateway_id           = ""
    nat_gateway_id             = ""
    network_interface_id       = ""
    transit_gateway_id         = ""
    vpc_endpoint_id            = ""
    vpc_peering_connection_id  = ""
  }]
}
resource "aws_route_table_association" "test_pub_rta" {
  subnet_id      = aws_subnet.test_pub_subnet.id
  route_table_id = aws_route_table.test_pub_rt.id
}
resource "aws_security_group" "test_sg" {
  vpc_id = aws_vpc.test_vpc.id
  name   = "test-sg"

  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "ssh"
      from_port        = "22"
      to_port          = "443"
      ipv6_cidr_blocks = ["::/0"]
      protocol         = "tcp"
      security_groups  = ["aws_security_group.test_sg.id"]
      self             = false
      prefix_list_ids  = []
    }
  ]
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "ssh"
      from_port        = "0"
      to_port          = "0"
      ipv6_cidr_blocks = ["::/0"]
      protocol         = "tcp"
      security_groups  = ["aws_security_group.test_sg.id"]
      self             = false
      prefix_list_ids  = []
    }
  ]

}

resource "aws_instance" "ec2test" {
  ami                         = "ami-0b0af3577fe5e3532"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = "test"
  subnet_id                   = aws_subnet.test_pub_subnet.id
  security_groups             = ["aws_security_group.test_sg.id"]
  vpc_security_group_ids      = ["aws_vpc_security_group."]
  user_data                   = <<-EOF
      #!/bin/bash
      sudo yum-config-manager --disable docker-ce-stable
      sudo yum update -y
      sudo yum upgrade -y
      sudo yum remove docker docker-common docker-selinux docker-engine -y
      sudo yum install vim epel-release yum-utils device-mapper-persistent-data lvm2 -y
      sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo -y
      sudo yum-config-manager --disable docker-ce-stable
      sudo yum install docker -y
      sudo systemctl enable docker.service
      sudo systemctl start docker.service
      echo "alias docker='sudo docker'" >> ~/.bashrc
      sudo hostnamectl set-hostname docker
      sudo groupadd docker
      sudo usermod -aG docker $USER
      EOF
}


terraform {
  backend "s3" {
    bucket = "yaznasivasai"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}


