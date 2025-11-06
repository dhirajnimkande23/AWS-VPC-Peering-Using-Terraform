# AWS-VPC-Peering-Using-Terraform
AWS VPC Peering Connection project with CLI commands, use case, and verification steps. This project helps connect two VPCs so resources in one VPC can communicate with resources in the other using private IPs.



**AWS VPC Peering Connection project** with CLI commands, use case, and verification steps. This project helps connect two VPCs so resources in one VPC can communicate with resources in the other using private IPs.

---

## ✅ **Project Title:**

**Create and Configure VPC Peering between Two VPCs Using AWS CLI**

---

```
sudo yum install git
git clone https://github.com/atulkamble/aws-vpc-peering.git
cd aws-vpc-peering
```
# info after provision 
```
atul@MacBook terraform % ls
key.pem			terraform.tfstate
main.tf			variables.tf
outputs.tf

atul@MacBook terraform % tree
.
├── key.pem
├── main.tf
├── outputs.tf
├── terraform.tfstate
└── variables.tf
```
# Outputs:

```
ssh_private_key_path = "./key.pem"
vm1_private_ip = "10.0.1.123"
vm1_public_ip = "18.212.127.3"
vm2_private_ip = "10.1.1.30"
vm2_public_ip = "54.197.23.222"
```

# copy key.pem to vm1
```
scp -i key.pem /Users/atul/Downloads/aws-vpc-peering/terraform/key.pem ec2-user@18.212.127.3://home/ec2-user

ls

```

# connect vm2 instance privately 
```
chmod 400 key.pem
ssh -i "key.pem" ec2-user@10.1.1.30
exit
```
# main.tf 
```
provider "aws" {
  region = var.region
}

# Generate key pair
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer_key" {
  key_name   = var.key_name
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "${path.module}/key.pem"
  file_permission = "0400"
}

# VPC1
resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc1_cidr
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.subnet1_cidr
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_security_group" "sg1" {
  name        = "sg1"
  description = "Allow SSH & ICMP from VPC2"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

# VPC2
resource "aws_vpc" "vpc2" {
  cidr_block = var.vpc2_cidr
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = var.subnet2_cidr
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw2" {
  vpc_id = aws_vpc.vpc2.id
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
  name        = "sg2"
  description = "Allow SSH & ICMP from VPC1"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

# VPC Peering
resource "aws_vpc_peering_connection" "peer" {
  vpc_id       = aws_vpc.vpc1.id
  peer_vpc_id  = aws_vpc.vpc2.id
  auto_accept  = true
}

resource "aws_route" "peer_route1" {
  route_table_id             = aws_route_table.rt1.id
  destination_cidr_block     = var.vpc2_cidr
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "peer_route2" {
  route_table_id             = aws_route_table.rt2.id
  destination_cidr_block     = var.vpc1_cidr
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer.id
}

# AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance in VPC1
resource "aws_instance" "vm1" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet1.id
  key_name                    = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids      = [aws_security_group.sg1.id]
  associate_public_ip_address = true

  tags = {
    Name = "VM1"
  }
}

# EC2 Instance in VPC2
resource "aws_instance" "vm2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet2.id
  key_name                    = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids      = [aws_security_group.sg2.id]
  associate_public_ip_address = true

  tags = {
    Name = "VM2"
  }
}
```
---
# outputs.tf
```
output "vm1_public_ip" {
  value = aws_instance.vm1.public_ip
}

output "vm2_public_ip" {
  value = aws_instance.vm2.public_ip
}

output "vm1_private_ip" {
  value = aws_instance.vm1.private_ip
}

output "vm2_private_ip" {
  value = aws_instance.vm2.private_ip
}

output "ssh_private_key_path" {
  value = local_file.private_key.filename
}
```
---
# variables.tf
```
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "vpc1_cidr" {
  description = "CIDR block for VPC 1"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc2_cidr" {
  description = "CIDR block for VPC 2"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet1_cidr" {
  description = "CIDR block for Subnet 1 (VPC1)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet2_cidr" {
  description = "CIDR block for Subnet 2 (VPC2)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "key_name" {
  description = "Name for SSH key pair"
  type        = string
  default     = "key"
}
```
---
```
aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem
chmod 400 my-key.pem
```
// copy files 
```
scp -i my-key.pem -r /Users/atul/Downloads/AWS-VPC-Peering-Project ec2-user@204.236.200.28:/home/ec2-user/
```

## 🎯 **Objective:**

To create a secure VPC peering connection between two different VPCs in the same AWS region and route traffic privately between their EC2 instances.

---

## 🧩 **Use Case:**

* **VPC-A**: Application server
* **VPC-B**: Database server
* Goal: Allow the app server in VPC-A to access the database in VPC-B over private IPs.

---

## 🏗️ **Step-by-Step Setup Using AWS CLI**

### 1️⃣ Create Two VPCs

```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications \
"ResourceType=vpc,Tags=[{Key=Name,Value=VPC-A}]"

aws ec2 create-vpc --cidr-block 10.1.0.0/16 --tag-specifications \
"ResourceType=vpc,Tags=[{Key=Name,Value=VPC-B}]"
```

### 2️⃣ Note the VPC IDs

```bash
aws ec2 describe-vpcs --query "Vpcs[*].{ID:VpcId,CIDR:CidrBlock}"
```

### 3️⃣ Create Subnets in Both VPCs

```bash
aws ec2 create-subnet --vpc-id <vpc-a-id> --cidr-block 10.0.1.0/24
aws ec2 create-subnet --vpc-id <vpc-b-id> --cidr-block 10.1.1.0/24
```

### 4️⃣ Create VPC Peering Connection

```bash
aws ec2 create-vpc-peering-connection --vpc-id <vpc-a-id> \
--peer-vpc-id <vpc-b-id> --tag-specifications \
"ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=VPC-A-B-Peering}]"
```

### 5️⃣ Accept the Peering Connection

```bash
aws ec2 describe-vpc-peering-connections

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id <peering-connection-id>
```

### 6️⃣ Update Route Tables (One for Each VPC)

```bash
# Get route table IDs
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-a-id>
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-b-id>

# Add routes
aws ec2 create-route --route-table-id <route-table-a-id> \
--destination-cidr-block 10.1.0.0/16 --vpc-peering-connection-id <peering-connection-id>

aws ec2 create-route --route-table-id <route-table-b-id> \
--destination-cidr-block 10.0.0.0/16 --vpc-peering-connection-id <peering-connection-id>
```

---

## 🚀 **Test Connectivity**

### Deploy EC2 Instances in Both VPCs:

```bash
aws ec2 run-instances --image-id ami-0c02fb55956c7d316 \
--count 1 --instance-type t2.micro --key-name mykey \
--security-group-ids <sg-id> --subnet-id <subnet-id>
```

### Add SG Rules to Allow ICMP or SSH:

```bash
aws ec2 authorize-security-group-ingress \
--group-id <sg-id> --protocol icmp --port -1 --cidr 10.0.0.0/8
```

### From one EC2, ping the other EC2’s private IP:

```bash
ping <private-ip-of-peer-ec2>
```

---

## 🧼 **Clean Up**

```bash
aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id <id>
aws ec2 delete-vpc --vpc-id <vpc-a-id>
aws ec2 delete-vpc --vpc-id <vpc-b-id>
```

---

## 📌 Diagram (Textual)

```
+----------------+      Peering      +----------------+
|     VPC-A      | <---------------> |     VPC-B      |
| 10.0.0.0/16    |                   | 10.1.0.0/16    |
|   EC2-A        |                   |   EC2-B        |
+----------------+                   +----------------+
```
# steps to perform
```

VPC Peering Connection 

1) Create VPC A | 10.0.0.0/16
2) Create VPC B | 10.1.0.0/32
3) Create Peering Connection 
4) Accept Peering Connection
5) Edit Route Table A 
Add B details and Peering Connection ID
6) Edit Route Table B 
Add A details and Peering Connection ID
5) Launch instance A to VPC A (Public Subnet with internet gateway) | SG - 22
6) Launch instance B to VPC B (Private Subnet) | SG 22
7) Connect instance A - SSH 
ping 
ssh -i mykey userB@private-ip
8) Suceesful Connection

9) Deletion
delete instances
delete peering connection 
delete vpc 

touch mykey.pem
chmod 400 mykey.pem

ssh -i mykey.pem ec2-user@10.1.0.10

```
---
---
## 👨‍💻 Author

**Dhiraj Nimkande**
