provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "firstvpc"
  }
}
resource "aws_internet_gateway" "ig1" {
  vpc_id = aws_vpc.vpc1.id
}
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id
  route = [{
    cidr_block                 = "0.0.0.0/0"
    gateway_id                 = "aws_internet_gateway.gw.id"
    carrier_gateway_id         = ["false"]
    destination_prefix_list_id = [""]
    egress_only_gateway_id     = ["false"]
    instance_id                = [""]
    transit_gateway_id         = ["false"]
    local_gateway_id           = ["false"]
    nat_gateway_id             = ["false"]
    network_interface_id       = ["false"]
    vpc_endpoint_id            = ["false"]
    vpc_peering_connection_id  = [""]
    network_interface_id       = ["false"]
    ipv6_cidr_block            = "::/0"
  }]

}
resource "aws_subnet" "sub1" {
  cidr_block        = "10.10.1.0/24"
  vpc_id            = aws_vpc.vpc1.id
  availability_zone = "us-east-1a"

}
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt1.id

}
resource "aws_security_group" "sg1" {
  name = "security1"

  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "ssh"
    from_port        = 22
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = ["false"]
    protocol         = "tcp"
    security_groups  = ["aws_security_group.sg1.id"]
    self             = false
    to_port          = 443
  }]
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "sshout"
    from_port        = 22
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = ["false"]
    protocol         = "tcp"
    security_groups  = ["aws_security_group.sg1.id"]
    self             = false
    to_port          = 443
  }]
}
resource "aws_network_interface" "ani1" {
  subnet_id       = aws_subnet.sub1.id
  private_ip      = "10.10.1.50"
  security_groups = ["aws_security_group.sg1.id"]
}

resource "aws_instance" "instance1" {
  ami                         = "ami-0b0af3577fe5e3532"
  key_name                    = "hug.pem"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.sub1.id
  security_groups             = ["aws_security_group.sg1.id"]
  tags = {
    "Name" = "test"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo -i
                apt update -y
                apt upgrade -y
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                service docker start
                usermod -aG docker ubuntu
                EOF

}

