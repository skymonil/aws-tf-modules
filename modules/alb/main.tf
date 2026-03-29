resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = true 
  load_balancer_type = "application"
  
  # Referencing the object
  security_groups    = var.alb_config.security_group_ids
  subnets            = var.alb_config.private_subnet_ids

  enable_deletion_protection = var.alb_config.enable_deletion_protection
  drop_invalid_header_fields = true 

  # The Dynamic Block Upgrade
  # Only creates the access_logs block IF logging is enabled AND a bucket is provided
  dynamic "access_logs" {
    for_each = var.alb_config.enable_access_logs && var.alb_config.access_log_bucket_name != null ? [1] : []
    content {
      bucket  = var.alb_config.access_log_bucket_name
      prefix  = "alb-logs"
      enabled = true
    }
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "default" {
  name                 = "${var.alb_name}-default-tg"
  protocol             = "HTTP"
  target_type          = "ip" 
  deregistration_delay = 30 
  
  # Referencing the object
  port                 = var.alb_config.backend_port
  vpc_id               = var.alb_config.vpc_id

  health_check {
    enabled             = true
    path                = var.alb_config.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 2  
    unhealthy_threshold = 3  
    timeout             = 5
    interval            = 15 
    matcher             = "200-399"
  }

  tags = local.common_tags
}

# 1. The HTTPS Listener (Only deployed if a certificate is provided)
resource "aws_lb_listener" "https" {
  # This acts as an if-statement.
  count             = var.alb_config.certificate_arn != null ? 1 : 0
  
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  
  # Enforce strict modern encryption (Drops support for vulnerable TLS 1.0/1.1)
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" 
  certificate_arn   = var.alb_config.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

# 2. The HTTP Listener (Redirects to HTTPS if cert exists, otherwise forwards)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  dynamic "default_action" {
    # If a cert exists, REDIRECT Port 80 to Port 443
    for_each = var.alb_config.certificate_arn != null ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    # If no cert exists, FORWARD traffic normally (The old behavior)
    for_each = var.alb_config.certificate_arn == null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.default.arn
    }
  }
}