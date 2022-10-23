
resource "aws_launch_template" "web_application_template" {
  name                                 = "web_application_template"
  image_id                             = data.aws_ami.amazon-linux-2.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t2.micro"
  key_name                             = "terraform"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.web_app_sg.id]
  user_data              = base64encode(file("userdata.sh"))

  iam_instance_profile {
    name = "ec2_ssm_param"
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      "Name" = "web application"
    }
  }
}
resource "aws_lb" "web_ALB" {
  name               = "web-ALB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

}

resource "aws_autoscaling_group" "web_app_ASG" {
  max_size            = 4
  min_size            = 2
  name                = "web_app_ASG"
  vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]

  launch_template {
    id = aws_launch_template.web_application_template.id
    version = "$Latest"
  }
   lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "ASG_to_ALB" {
  autoscaling_group_name = aws_autoscaling_group.web_app_ASG.id
  lb_target_group_arn = aws_lb_target_group.app_ALB_target.arn
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



resource "aws_lb_target_group" "app_ALB_target" {
  name        = "app-ALB-target"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.web_app_vpc.id
  target_type = "instance"
  health_check {
    interval = 10
    path = "/"
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 5
    unhealthy_threshold = 2
  }
}

#resource "aws_lb_target_group_attachment" "lb_attachment" {
#  target_group_arn = aws_lb_target_group.app_ALB_target.arn
#  target_id        = [for ins in aws]
#  port = 80
#}

resource "aws_lb_listener" "web_app_listener" {
  load_balancer_arn = aws_lb.web_ALB.arn
  protocol          = "HTTP"
  port              = "80"

  default_action {
    target_group_arn = aws_lb_target_group.app_ALB_target.arn
    type             = "forward"
  }
}