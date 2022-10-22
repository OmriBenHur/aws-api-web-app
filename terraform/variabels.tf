
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

variable "vpc_cidr_def" {
  description = "VPC cidr"
  default     = "10.0.0.0/16"
}


variable "public_rtb_cidr" {
  description = "Public Route Table"
  default     = "0.0.0.0/0"
}

variable "private_rtb_cidr" {
  description = "Private Route Table"
  default     = "0.0.0.0/0"
}


variable "public_subnet_1" {
  description = "Public Subnet cidr"
  default     = "10.0.1.0/24"
}

variable "public_subnet_2" {
  description = "Public Subnet cidr"
  default     = "10.0.3.0/24"
}

variable "private_subnet_1" {
  description = "Private Subnet cidr"
  default     = "10.0.2.0/24"

}

variable "private_subnet_2" {
  description = "Private Subnet cidr"
  default     = "10.0.4.0/24"
}


variable "az_1" {
  description = "First Availability Zone"
  default     = "us-west-2a"
}

variable "az_2" {
  description = "Second Availability Zone"
  default     = "us-west-2b"
}
