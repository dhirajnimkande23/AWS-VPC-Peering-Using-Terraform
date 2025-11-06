variable "region" {
  description = "The AWS region to create resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc1_cidr" {
  description = "The CIDR block for the VPC1"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet1_cidr" {
  description = "The CIDR block for the subnet1 in VPC1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone1" {
  description = "The availability zone for subnet1"
  type        = string
  default     = "us-east-1a"
}

variable "vpc2_cidr" {
  description = "The CIDR block for VPC2"
  type        = string
  default     = "10.1.0.0/16"
}

variable "vpc2_subnet2_cidr" {
  description = "The CIDR block for subnet2 in VPC2"
  type        = string
  default     = "10.1.1.0/24"
}

