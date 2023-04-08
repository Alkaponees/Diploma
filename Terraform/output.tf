output "load_balancer_url" {
  value = aws_elb.web.dns_name
}
