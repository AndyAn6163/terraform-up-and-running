# 如果你能對模組執行 terraform apply 就會被視為根模組 root moudle
# 非根模組不會有 providers 因此 providers 拿掉

resource "aws_lb" "example" {
  name               = var.cluster_name
  load_balancer_type = "application"
  # in prod evnironment, alb should place in public subnets, but in default vpc all subnets are public subnets
  subnets         = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_lb_target_group" "asg" {
  name     = var.cluster_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "example" {
  launch_template {
    id = aws_launch_template.example.id
    # refreshing instance after launch template update (e.g. user_data)
    # 如果不指定 versrion 是最新的 version
    # aws_launch_template 的 user_data 改變時，launch_template 更新了一版 (如第二版)
    # 但 aws_autoscaling_group 還是使用舊版 launch_template (如第一版)
    version = aws_launch_template.example.latest_version
  }

  # refreshing instance after launch template update (e.g. user_data)
  # 透過 instance_refresh 當 aws_launch_template 的 user_data 改變時自動更新 instance
  instance_refresh {
    strategy = "Rolling"
  }

  # in prod evnironment, ASG's instances should place in private subnets, but in default vpc all subnets are public subnets
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.asg.arn]
  health_check_type   = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

}

# Launch Configurations to de deprecated On October 1st 2024
# The Launch Configuration creation operation is not available in your account. 
# Use launch templates to create configuration templates for your Auto Scaling groups.
# https://pet2cattle.com/2021/08/convert-launch-configuration-to-launch-template
resource "aws_launch_template" "example" {
  image_id               = "ami-0ea3c35c5c3284d82"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]

  # refreshing instance after launch template update (e.g. user_data)
  # Whether to update Default Version each update. Conflicts with default_version.
  update_default_version = true


  # new user_data
  # 雖然是紅字，但測試時是可以傳遞參數
  # user-data.sh 可以接收參數並且顯示在 html 上
  # ${path.module} 傳回定義這個表示式的模組所在的檔案系統路徑
  # 即從 source = "../../../modules/services/webserver-cluster" 開始定義路徑
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }))

  # origin user_data 
  # user_data = base64encode(data.template_file.user_data_demo.rendered)

  # Required when using a launch configuration with an auto scaling group
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"
}

resource "aws_security_group_rule" "allow_server_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = var.server_port
  to_port     = var.server_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_server_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = local.ssh_port
  to_port     = local.ssh_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.ec2_instance_connect_ips

  # AWS IP address ranges
  # https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-ranges.html
  # https://ip-ranges.amazonaws.com/ip-ranges.json
  # https://stackoverflow.com/questions/56917634/amazon-ec2-instance-connect-for-ssh-security-group
  # {
  #  "ip_prefix": "3.16.146.0/29",
  #  "region": "us-east-2",
  #  "service": "EC2_INSTANCE_CONNECT",
  #  "network_border_group": "us-east-2"
  # }
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.isp_ips
}

resource "aws_security_group_rule" "allow_http_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips

  # Allow all outbound requests
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group.html
  # By default, AWS creates an ALLOW ALL egress rule when creating a new Security Group inside of a VPC.
  # When creating a new Security Group inside a VPC, Terraform will remove this default rule, 
  # and require you specifically re-create it if you desire that rule. 
  # We feel this leads to fewer surprises in terms of controlling your egress rules. 
  # If you desire this rule to be in place, you can use this egress block
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_stae_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}

# Setting backend to remote backend s3
# 使用新的 key，因此狀態檔案與 s3 分開
# terraform init -backend-config ./backend.hcl
terraform {
  backend "s3" {
    key = "stage/services/web-server-cluster/terraform.tfstate"
  }
}

locals {
  http_port                = 80
  ssh_port                 = 22
  any_port                 = 0
  any_protocol             = "-1"
  tcp_protocol             = "tcp"
  all_ips                  = ["0.0.0.0/0"]
  ec2_instance_connect_ips = ["3.16.146.0/29"]
  isp_ips                  = ["106.1.226.0/24", "1.169.157.108/30"]
}

