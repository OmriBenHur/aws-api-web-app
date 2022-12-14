# cloudwatch to monitor auto scaling group instances cpu load
# and activate scale out policy if load in over 80%
resource "aws_cloudwatch_metric_alarm" "cpu_overload" {
  alarm_name          = "cpu_overload"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_ASG.name
  }
  alarm_description = "This metric monitors ec2 cpu utilization and scales it down if cpu load is iver 80%"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]
}


# cloudwatch to monitor auto scaling group instances cpu load
# and activate scale in policy if cpu load is over 35%
resource "aws_cloudwatch_metric_alarm" "cpu_underload" {
  alarm_name          = "cpu_underload"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "35"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_ASG.name
  }
  alarm_description = "This metric monitors ec2 cpu utilization and scales it up if load is under 35%"
  alarm_actions     = [aws_autoscaling_policy.scale_down_policy.arn]
}
