# web app security group to allow traffic from alb
resource "aws_security_group" "web_app_sg" {
  name        = "web_app_sg"
  description = "Allow lb inbound traffic"
  vpc_id      = aws_vpc.web_app_vpc.id

  ingress {
    description     = "Allow HTTP Traffic"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
#
#  ingress {
#    description     = "Allow ssh Traffic"
#    from_port       = 22
#    to_port         = 22
#    protocol        = "tcp"
#    security_groups = [aws_security_group.lb_sg.id]
#  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    role = "Allow lb Traffic"
  }
}

# application load balancer security group to allow traffic from the internet
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.web_app_vpc.id

  ingress {
    description = "Allow HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#
#  ingress {
#    description = "Allow ssh Traffic"
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
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

# vpc endpoint security group to allow https traffic from ec2 instances
# to communicate with secrets manager
resource "aws_security_group" "vpce_sg" {
  name        = "vpc-endpoint-sg"
  description = "Allow traffic for secrets manager"
  vpc_id      = aws_vpc.web_app_vpc.id

  ingress {
    description     = "Allow HTTPs Traffic"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.web_app_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    role = "Allow secrets manager Traffic"
  }
}

# iam role for ec2 to allow the secrets manager : get secret value operation
# this is required for the web app container to function
resource "aws_iam_role" "ec2-to-sec-man" {
  name               = "ec2_secret_manager"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json

  inline_policy {
    name = "ec2_secret_manager"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : "secretsmanager:GetSecretValue",
          "Resource" : "arn:aws:secretsmanager:us-west-2:967980209513:secret:web-app/api-key-qE9pu3"
        }
      ]
    })
  }
}

# creating iam instance profile from iam role to use in the launch template
# to be used with ASG. (regular roles cannot attach to launch templates or instances)
resource "aws_iam_instance_profile" "ec2_role_profile" {
  name = "ec2_secrets_manager"
  role = aws_iam_role.ec2-to-sec-man.name
}