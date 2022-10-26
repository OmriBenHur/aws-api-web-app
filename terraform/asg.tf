# launch template to use in auto scaling group
resource "aws_launch_template" "web_application_template" {
  name                                 = "web_application_template"
  image_id                             = data.aws_ami.amazon-linux-2.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t2.micro"
  key_name                             = "lab-key"

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.web_app_sg.id]
  user_data              = base64encode(file("userdata.sh"))

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_role_profile.arn
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      "Name" = "web application"
    }
  }
}


# auto scaling group to be deployed in private subnets
resource "aws_autoscaling_group" "web_app_ASG" {
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  name                = "web_app_ASG"
  vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]
  depends_on          = [aws_launch_template.web_application_template]
  default_cooldown    = 100

  launch_template {
    id      = aws_launch_template.web_application_template.id
    version = "$Latest"
  }
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}


# attaching auto scaling group to application load balancer
resource "aws_autoscaling_attachment" "ASG_to_ALB" {
  autoscaling_group_name = aws_autoscaling_group.web_app_ASG.id
  lb_target_group_arn    = aws_lb_target_group.app_ALB_target.arn
}


# scaling policy to add an instance via cloudwatch alarms
resource "aws_autoscaling_policy" "scale_up_policy" {
  autoscaling_group_name = aws_autoscaling_group.web_app_ASG.name
  name                   = "scale up policy"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300

}

# scaling policy to remove an instance via cloudwatch alarms
resource "aws_autoscaling_policy" "scale_down_policy" {
  autoscaling_group_name = aws_autoscaling_group.web_app_ASG.name
  name                   = "scale down policy"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 150
}

