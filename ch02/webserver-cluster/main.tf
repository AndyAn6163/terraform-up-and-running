provider "aws" {
  region = "us-east-2"
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.default.ids

  min_size = 2
  max_size = 3

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
  
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-0ea3c35c5c3284d82"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello World, Andy~" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOF

  # Required when using a launch configuration with an auto scaling group
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["106.1.226.0/24"]  
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["3.16.146.0/29"]
  }
  
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

