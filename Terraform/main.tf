provider "aws" {
  region     = "eu-north-1"
  secret_key = var.aws_secret_key
  access_key = var.aws_access_key
}
resource "aws_default_vpc" "default" {}

data "aws_availability_zones" "available" {}

data "aws_ami" "latest_Ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
resource "aws_security_group" "web" {
  name   = "MySecurityGroup"
  vpc_id = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each = ["80", "443", "22","8080"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "Default SG"
  }
}
resource "aws_security_group" "TFDefault" {
  name   = "MySecurityGroup"
  vpc_id = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each = ["3306","22","80"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "Default SG"
  }
}
resource "aws_instance" "MySQL_instance"{
    ami = "ami-09e1162c87f73958b"
    instance_type = "t3.micro"
    key_name = "Stockholm_RSA"
    tags = {
      "Name" = "MYSQL_Server"
    }
    user_data = "${file("../bash/install_MYSQL.sh")}"
    vpc_security_group_ids = [aws_security_group.TFDefault.id]
    ebs_block_device {
      device_name = "/dev/sda1"
      volume_type ="gp3"
      volume_size = 20
      encrypted = true
      delete_on_termination = true

    }
}

resource "aws_launch_configuration" "web" {
  name_prefix     = "Web server configuration"
  image_id        = data.aws_ami.latest_Ubuntu.id
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.web.id]
  key_name = "Stockholm_RSA"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Default subnet eu-north-1a"
  }
}


resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Default subnet eu-north-1b"
  }
}

resource "aws_autoscaling_group" "web" {
  name                 = "Auto Scaling Group ${aws_launch_configuration.web.name}"
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 2
  max_size             = 4
  min_elb_capacity     = 2
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  load_balancers       = [aws_elb.web.name]

  dynamic "tag" {
    for_each = {
      Name   = "Web Server"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_elb" "web" {
  name               = "Load-Balancer"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups    = [aws_security_group.web.id]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }

  tags = {
    "Name" = "Elastic Load Balancer"
  }
}



resource "aws_autoscaling_policy" "example-cpu-policy" {
  name                   = "example-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "120"
  policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "example-cpu-alarm" {
  alarm_name          = "example-cpu-alarm"
  alarm_description   = "example-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.web.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.example-cpu-policy.arn}"]
}
# scale down alarm
resource "aws_autoscaling_policy" "example-cpu-policy-scaledown" {
  name                   = "example-cpu-policy-scaledown"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "120"
  policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "example-cpu-alarm-scaledown" {
  alarm_name          = "example-cpu-alarm-scaledown"
  alarm_description   = "example-cpu-alarm-scaledown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.web.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.example-cpu-policy-scaledown.arn}"]
}
