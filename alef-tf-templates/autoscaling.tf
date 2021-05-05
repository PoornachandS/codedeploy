data "aws_kms_key" "by_alias" {
  key_id = "alias/alef"
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP/S inbound traffic"
  vpc_id      = "vpc-85f658f8"
  
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "http call"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http/s"
  }
}

resource "aws_launch_template" "template" {
  name_prefix   = var.template_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = "alef"
  block_device_mappings {
    device_name = "/dev/sdb"

    ebs {
      volume_size = 20
      encrypted   = true
      volume_type = "gp2"
      kms_key_id  = data.aws_kms_key.by_alias.arn
      delete_on_termination = false
    }
  }
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      encrypted   = true
      volume_type = "gp2"
      kms_key_id  = data.aws_kms_key.by_alias.arn
      delete_on_termination = false
    }
  }
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  iam_instance_profile {
    name = "Ec2ServiceRole"
  }
  user_data = filebase64("codedeployagent.sh")
}

resource "aws_autoscaling_group" "alef-group" {
  name = "alef-asg-group"
  max_size = 3
  min_size = 1
  desired_capacity = 2
  vpc_zone_identifier = ["subnet-908210f6","subnet-c80f96e9"]
  load_balancers = [aws_elb.alef-elb.name]
  launch_template {
    id      = aws_launch_template.template.id
    version = aws_launch_template.template.latest_version
  }
  tag {
    key                 = "Name"
    value               = "codedeploy"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.alef-group.id
  elb                    = aws_elb.alef-elb.id
}

/*
resource "aws_autoscaling_policy" "alef-group-scaling" {
  name = "alef-asg-policy"
  autoscaling_group_name = aws_autoscaling_group.alef-group.name
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 80.0
  }
  }
*/
