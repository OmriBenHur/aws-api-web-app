provider "aws" {
  region     = "us-west-2"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "web_app_vpc" {
  cidr_block = var.vpc_cidr_def
  tags = {
    Name = "Web App VPC"
  }
}


resource "aws_internet_gateway" "web_app_igw" {
  vpc_id = aws_vpc.web_app_vpc.id
}


resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.web_app_vpc.id
  cidr_block        = var.public_subnet_1
  availability_zone = var.az_1

  tags = {
    Name = "Public Subnet 1"
  }
}


resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.web_app_vpc.id
  cidr_block        = var.public_subnet_2
  availability_zone = var.az_2

  tags = {
    Name = "Public Subnet 2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.web_app_vpc.id
  cidr_block        = var.private_subnet_1
  availability_zone = var.az_1

  tags = {
    Name = "Private Subnet 1"
  }
}


resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.web_app_vpc.id
  cidr_block        = var.private_subnet_2
  availability_zone = var.az_2

  tags = {
    Name = "Private Subnet 2"
  }
}


resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.web_app_vpc.id

  route {
    cidr_block = var.public_rtb_cidr
    gateway_id = aws_internet_gateway.web_app_igw.id
  }

  tags = {
    Name = "Public RTB"
  }
}

resource "aws_eip" "nat_1_eip" {
  vpc = true
  tags = {
    Name = "EIP 1"
  }
}


resource "aws_eip" "nat_2_eip" {
  vpc = true
  tags = {
    Name = "EIP 2"
  }
}

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "NAT Gateway 1"
  }
}


resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2_eip.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "NAT Gateway 2"
  }
}


resource "aws_route_table" "private_rtb_1" {
  vpc_id = aws_vpc.web_app_vpc.id

  route {
    cidr_block     = var.private_rtb_cidr
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = {
    Name = "Private RTB 1"
  }
}


resource "aws_route_table" "private_rtb_2" {
  vpc_id = aws_vpc.web_app_vpc.id

  route {
    cidr_block     = var.private_rtb_cidr
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = {
    Name = "Private RTB 2"
  }
}


resource "aws_route_table_association" "public_1_rtb_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rtb.id
}


resource "aws_route_table_association" "public_2_rtb_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rtb.id
}


resource "aws_route_table_association" "private_1_rtb_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rtb_1.id
}


resource "aws_route_table_association" "private_2_rtb_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rtb_2.id
}


resource "aws_security_group" "web_app_sg" {
  name        = "web_app_sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.web_app_vpc.id

  ingress {
    description = "Allow HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ssh Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    role = "Allow HTTP Traffic"
  }
}
#
#resource "aws_instance" "ec2_private" {
#  ami = data.aws_ami.amazon-linux-2.id
#  #associate_public_ip_address = true
#  instance_type          = "t2.micro"
#  key_name               = "terraform"
#  subnet_id              = aws_subnet.private_subnet_1.id
#  vpc_security_group_ids = [aws_security_group.web_app_sg.id]
#  user_data              = file("userdata.sh")
#  iam_instance_profile   = "ec2_ssm_param"
#
#  tags = {
#    "Name" = "EC2-private"
#  }
#
#}
#
#resource "aws_instance" "ec2_public" {
#  ami                         = data.aws_ami.amazon-linux-2.id
#  associate_public_ip_address = true
#  instance_type               = "t2.micro"
#  key_name                    = "terraform"
#  subnet_id                   = aws_subnet.public_subnet_1.id
#  vpc_security_group_ids      = [aws_security_group.web_app_sg.id]
#  iam_instance_profile        = "ec2_ssm_param"
#  user_data                   = file("userdata.sh")
#
#  tags = {
#    "Name" = "EC2-PUBLIC"
#  }
#
#}

resource "aws_launch_template" "web_application_template" {
  name                                 = "web_application_template"
  image_id                             = data.aws_ami.amazon-linux-2.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t2.micro"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.web_app_sg.id]
  user_data              = base64encode(file("userdata.sh"))

  iam_instance_profile {
    name = "ec2_ssm_param"
  }

  tags = {
    "Name" = "web application launch template"
  }
}

resource "aws_autoscaling_group" "web_app_ASG" {
  max_size            = 4
  min_size            = 2
  name                = "web_app_ASG"
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_template {
    id = aws_launch_template.web_application_template.id
  }
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  autoscaling_group_name = aws_autoscaling_group.web_app_ASG.name
  name                   = "scale up policy"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 150
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  autoscaling_group_name = aws_autoscaling_group.web_app_ASG.name
  name                   = "scale down policy"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 150
}
resource "aws_cloudwatch_metric_alarm" "cpu_overload" {
  alarm_name          = "cpu_overload"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_ASG.name
  }
  alarm_description = "This metric monitors ec2 cpu utilization and scales it down if cpu load is iver 80%"
  alarm_actions     = [aws_autoscaling_policy.scale_down_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_underload" {
  alarm_name          = "cpu_underload"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "35"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_ASG.name
  }
  alarm_description = "This metric monitors ec2 cpu utilization and scales it up if load is under 35%"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]
}

#resource "aws_applic" "" {}
