module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  name = "terraform-asg-kunjan"

  min_size                  = 1
  max_size                  = 5
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["subnet-09a50a0db3bdf9d87", "subnet-0c7ecd015c8189600"]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 60
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  # Launch template
  launch_template_name        = "terraform-lt-kunjan"
  launch_template_description = "Launch template example"
  update_default_version      = true

  image_id          = "ami-0dd1dee36749e98e8"
  instance_type     = "t3a.small"
  key_name          = "terraform"
  user_data         = filebase64("init.sh")
  ebs_optimized     = true
  enable_monitoring = true

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "example-asg"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Name = "terraform-asg-kunjan"
  }
}

####################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "alb-terraform-kunjan"

  load_balancer_type = "application"

  vpc_id             = "vpc-036d31bd5fc70a5ef" # Entered alredy created vpc 'VPC-SquareOps-Ohio'
  subnets            = ["subnet-09a50a0db3bdf9d87", "subnet-0c7ecd015c8189600"] # Public Subnets IDS for VPC
  security_groups    = ["sg-0ddeb3fa52ec1ac31"] # Added Created SG Id with allowed ports "22,80,443"

  target_groups = [
    {
      name_prefix      = "Tkunj" # treat as prefix of load-balancer-name
      backend_protocol = "HTTP" # Backend Protocol
      backend_port     = 80 # Backend port
      target_type      = "instance" # This Load-balancer will target instance
    }
  ]

  https_listeners = [
    {
      port               = 443 # adding listner port
      protocol           = "HTTPS" # adding listner protocol
      certificate_arn    = "arn:aws:acm:us-east-2:421320058418:certificate/df35a587-5429-4738-9477-5032add3142d" # adding approved ACM certificate ARN num.
      target_group_index = 0 # It's not clear
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80 # adding listner port
      protocol           = "HTTP" # adding listner protocol
      target_group_index = 0 # It's not clear
    }
  ]

  tags = {
    Name = "terraform-tg-kunjan" # Name of target Group
  }
}

# Create a new load balancer attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = ${module.aws_autoscaling_group.terraform-asg-kunjan.id}
  alb                    = aws_alb.alb-terraform-kunjan.id
}
# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_attachment_tg" {
  autoscaling_group_name = aws_autoscaling_group.terraform-asg-kunjan.id
  lb_target_group_arn    = aws_lb_target_group.terraform-tg-kunjan.arn
}
