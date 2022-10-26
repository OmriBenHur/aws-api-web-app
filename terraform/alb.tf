# application load balancer to be deployed in public subnets
resource "aws_lb" "web_ALB" {
  name               = "web-ALB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]


}

# application load balancer target group
resource "aws_lb_target_group" "app_ALB_target" {
  name        = "app-ALB-target"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.web_app_vpc.id
  target_type = "instance"
  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 20
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

# application load balancer listener to forward comm to instances
resource "aws_lb_listener" "web_app_listener" {
  load_balancer_arn = aws_lb.web_ALB.arn
  protocol          = "HTTP"
  port              = "80"

  default_action {
    target_group_arn = aws_lb_target_group.app_ALB_target.arn
    type             = "forward"
  }
}