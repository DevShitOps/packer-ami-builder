resource "aws_launch_template" "launch-template-arm64" {
  name = var.launch_template_name

  image_id = var.ami_id
  key_name = "ec2-keypair"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = 50
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      snapshot_id           = var.snapshot_id
      encrypted             = false
    }
  }
  instance_initiated_shutdown_behavior = "terminate"
  disable_api_stop                     = false
  disable_api_termination              = false
  ebs_optimized                        = false
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = ["sg-xxxxxxxxxxxxx", "sg-xxxxxxxxxxxxx"]
  }
  tags = {
    packer-group = var.packer_group
  }

  iam_instance_profile {
    arn = var.instance_profile_arn
  }
  metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "optional"
  instance_metadata_tags      = "disabled"
  }
  user_data = filebase64("user-data.sh")
}
