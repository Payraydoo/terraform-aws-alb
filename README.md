# Terraform AWS ALB Module

This module creates an Application Load Balancer (ALB) with target groups and listeners.

## Features

- Creates an Application Load Balancer
- Creates target groups
- Configures HTTPS listener with SSL certificate
- Sets up security groups
- Configures logging and monitoring
- Standardized tagging system

## Usage

```hcl
module "alb" {
  source  = "your-org/alb/terraform"
  version = "0.1.0"
  
  tag_org        = "company"
  env            = "dev"
  vpc_id         = module.vpc.id
  security_groups = [module.vpc.vpc_default_sg_id, module.cloudflare-sg.id]
  subnets        = module.vpc.public_subnet_ids
  certificate_arn = data.aws_acm_certificate.name.arn
  
  # Optional settings
  target_groups = [
    {
      name             = "api"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  ]
  
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      action_type        = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
  
  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = data.aws_acm_certificate.name.arn
      action_type        = "forward"
      target_group_index = 0
    }
  ]
  
  tags = {
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |
| cloudflare | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| tag_org | Organization tag | `string` | n/a | yes |
| env | Environment (dev, staging, prod) | `string` | n/a | yes |
| vpc_id | VPC ID where ALB will be created | `string` | n/a | yes |
| security_groups | List of security group IDs to assign to the ALB | `list(string)` | n/a | yes |
| subnets | List of subnet IDs where ALB will be created | `list(string)` | n/a | yes |
| certificate_arn | ARN of the SSL certificate to use for HTTPS listeners | `string` | n/a | yes |
| target_groups | List of target group configurations | `list(object)` | `[]` | no |
| http_tcp_listeners | List of HTTP/TCP listener configurations | `list(object)` | `[]` | no |
| https_listeners | List of HTTPS listener configurations | `list(object)` | `[]` | no |
| idle_timeout | Idle timeout for connections in seconds | `number` | `60` | no |
| enable_deletion_protection | Whether to enable deletion protection | `bool` | `false` | no |
| enable_access_logs | Whether to enable access logs | `bool` | `true` | no |
| access_logs_bucket | S3 bucket name to store access logs | `string` | `""` | no |
| access_logs_prefix | S3 bucket prefix to store access logs | `string` | `"alb-logs"` | no |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ALB ID |
| arn | The ALB ARN |
| dns_name | The DNS name of the ALB |
| zone_id | The zone ID of the ALB |
| target_group_arns | List of target group ARNs |
| target_group_names | List of target group names |
| http_tcp_listener_arns | List of HTTP/TCP listener ARNs |
| https_listener_arns | List of HTTPS listener ARNs |
| security_group_id | Security group ID for the ALB |

## Cloudflare Integration

To use Cloudflare for DNS records pointing to the ALB, use the Cloudflare provider:

```hcl
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "alb" {
  zone_id = var.cloudflare_zone_id
  name    = "app"
  value   = module.alb.dns_name
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

# Create a security group to allow Cloudflare IPs only
module "cloudflare-sg" {
  source = "your-org/security-group/aws"
  
  tag_org = var.tag_org
  env     = var.env
  vpc_id  = module.vpc.id
  name    = "cloudflare"
  
  # Cloudflare IP ranges
  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Cloudflare HTTPS"
      cidr_blocks = "173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,172.64.0.0/13,131.0.72.0/22"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Cloudflare HTTP"
      cidr_blocks = "173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,172.64.0.0/13,131.0.72.0/22"
    }
  ]
}
```