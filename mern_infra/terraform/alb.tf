resource "aws_lb" "app_alb" {
  count              = var.create_alb ? 1 : 0
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets            = [aws_subnet.public.id]
}

resource "aws_lb_target_group" "app_tg" {
  count    = var.create_alb ? 1 : 0
  name     = "${var.project_name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "front_listener" {
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.app_alb[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg[0].arn
  }
}

// alb_dns_name output moved to outputs.tf and made conditional
