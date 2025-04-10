# Create ALB security group
resource "aws_security_group" "this" {
  name        = "${var.tag_org}-${var.env}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-alb-sg"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create the ALB
resource "aws_lb" "this" {
  name               = "${var.tag_org}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = concat([aws_security_group.this.id], var.security_groups)
  subnets            = var.subnets
  
  idle_timeout                     = var.idle_timeout
  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = true
  
  # Access logs
  dynamic "access_logs" {
    for_each = var.enable_access_logs && var.access_logs_bucket != "" ? [1] : []
    
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }
  
  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-alb"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create target groups
resource "aws_lb_target_group" "this" {
  count = length(var.target_groups)
  
  name        = "${var.tag_org}-${var.env}-${var.target_groups[count.index].name}-tg"
  port        = var.target_groups[count.index].backend_port
  protocol    = var.target_groups[count.index].backend_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_groups[count.index].target_type
  
  deregistration_delay = lookup(var.target_groups[count.index], "deregistration_delay", 300)
  
  dynamic "health_check" {
    for_each = lookup(var.target_groups[count.index], "health_check", {}) != {} ? [var.target_groups[count.index].health_check] : []
    
    content {
      enabled             = lookup(health_check.value, "enabled", true)
      interval            = lookup(health_check.value, "interval", 30)
      path                = lookup(health_check.value, "path", "/")
      port                = lookup(health_check.value, "port", "traffic-port")
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", 3)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", 3)
      timeout             = lookup(health_check.value, "timeout", 5)
      protocol            = lookup(health_check.value, "protocol", "HTTP")
      matcher             = lookup(health_check.value, "matcher", "200")
    }
  }
  
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = lookup(var.target_groups[count.index], "stickiness_enabled", false)
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-${var.target_groups[count.index].name}-tg"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create HTTP/TCP listeners
resource "aws_lb_listener" "http_tcp" {
  count = length(var.http_tcp_listeners)
  
  load_balancer_arn = aws_lb.this.arn
  port              = var.http_tcp_listeners[count.index].port
  protocol          = var.http_tcp_listeners[count.index].protocol
  
  dynamic "default_action" {
    for_each = var.http_tcp_listeners[count.index].action_type == "redirect" ? [1] : []
    
    content {
      type = "redirect"
      
      redirect {
        port        = lookup(var.http_tcp_listeners[count.index].redirect, "port", "443")
        protocol    = lookup(var.http_tcp_listeners[count.index].redirect, "protocol", "HTTPS")
        status_code = lookup(var.http_tcp_listeners[count.index].redirect, "status_code", "HTTP_301")
        host        = lookup(var.http_tcp_listeners[count.index].redirect, "host", "#{host}")
        path        = lookup(var.http_tcp_listeners[count.index].redirect, "path", "/#{path}")
        query       = lookup(var.http_tcp_listeners[count.index].redirect, "query", "#{query}")
      }
    }
  }
  
  dynamic "default_action" {
    for_each = var.http_tcp_listeners[count.index].action_type == "forward" ? [1] : []
    
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[var.http_tcp_listeners[count.index].target_group_index].arn
    }
  }
  
  dynamic "default_action" {
    for_each = var.http_tcp_listeners[count.index].action_type == "fixed-response" ? [1] : []
    
    content {
      type = "fixed-response"
      
      fixed_response {
        content_type = lookup(var.http_tcp_listeners[count.index].fixed_response, "content_type", "text/plain")
        message_body = lookup(var.http_tcp_listeners[count.index].fixed_response, "message_body", "")
        status_code  = lookup(var.http_tcp_listeners[count.index].fixed_response, "status_code", "200")
      }
    }
  }
  
  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-http-listener-${var.http_tcp_listeners[count.index].port}"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create HTTPS listeners
resource "aws_lb_listener" "https" {
  count = length(var.https_listeners)
  
  load_balancer_arn = aws_lb.this.arn
  port              = var.https_listeners[count.index].port
  protocol          = var.https_listeners[count.index].protocol
  ssl_policy        = lookup(var.https_listeners[count.index], "ssl_policy", "ELBSecurityPolicy-TLS13-1-2-2021-06")
  certificate_arn   = var.https_listeners[count.index].certificate_arn
  
  dynamic "default_action" {
    for_each = var.https_listeners[count.index].action_type == "forward" ? [1] : []
    
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[var.https_listeners[count.index].target_group_index].arn
    }
  }
  
  dynamic "default_action" {
    for_each = var.https_listeners[count.index].action_type == "fixed-response" ? [1] : []
    
    content {
      type = "fixed-response"
      
      fixed_response {
        content_type = lookup(var.https_listeners[count.index].fixed_response, "content_type", "text/plain")
        message_body = lookup(var.https_listeners[count.index].fixed_response, "message_body", "")
        status_code  = lookup(var.https_listeners[count.index].fixed_response, "status_code", "200")
      }
    }
  }
  
  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-https-listener-${var.https_listeners[count.index].port}"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}