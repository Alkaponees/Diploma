output "load_balancer_url" {
  value = aws_elb.web.dns_name
}
output "MySQL_instance_ip" {
    value=aws_instance.MySQL_instance.public_ip
  
}