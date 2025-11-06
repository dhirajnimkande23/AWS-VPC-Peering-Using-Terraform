# Create VPC-1
resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc1_cidr

  tags = {
    Name = "VPC-1"
  }
}

#Create subnet in VPC-1
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "VPC-1-IGW"
  }
}
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }

  tags = {
    Name = "VPC-1-RT"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_security_group" "sg1" {
  name        = "vpc1-sg"
  description = "Security group for VPC1"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc2_cidr]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc2_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create VPC-2
resource "aws_vpc" "vpc2" {
  cidr_block = var.vpc2_cidr

  tags = {
    Name = "VPC-2"
  }
}

#Create subnet in VPC-2
resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = var.vpc2_subnet2_cidr
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw2" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "VPC-2-IGW"
  }
}

resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw2.id
  }
}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt2.id
}

resource "aws_security_group" "sg2" {
  name        = "vpc2-sg"
  description = "Security group for VPC2"
  vpc_id      = "aws_vpc.vpc2.id"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create VPC Peering Connection
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id      = aws_vpc.vpc1.id
  peer_vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "VPC1-VPC2-Peering"
  }
}

# Update Route Tables for VPC Peering
resource "aws_route" "vpc1_to_vpc2" {
  route_table_id            = aws_route_table.rt1.id
  destination_cidr_block    = var.vpc2_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route" "vpc2_to_vpc1" {
  route_table_id            = aws_route_table.rt2.id
  destination_cidr_block    = var.vpc1_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# AMI
data "aws_ami" "amazon_linux" {

  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

# Launch EC2 Instance in VPC-1
resource "aws_instance" "VM1" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.sg1.id]
  key_name                    = aws_key_pair.vpc-key.key_name
  associate_public_ip_address = true
  tags = {
    Name = "VPC1-Instance"
  }
}
# Launch EC2 Instance in VPC-2
resource "aws_instance" "VM2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.subnet2.id
  vpc_security_group_ids      = [aws_security_group.sg2.id]
  key_name                    = aws_key_pair.vpc-key.key_name
  associate_public_ip_address = true
  tags = {
    Name = "VPC2-Instance"
  }
}
