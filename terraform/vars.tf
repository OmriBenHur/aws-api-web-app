provider "aws" {
  region     = "us-west-2"
  access_key = ""
  secret_key = ""
}

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

variable "app_count" {
  type    = number
  default = 1
}
