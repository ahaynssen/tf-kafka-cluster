resource "aws_launch_configuration" "zookeeper" {
  count         = "${var.zookeeper_cluster_size}"
  image_id      = "${lookup(var.amis, var.region)}"
  instance_type = "${var.zookeeper_instance_type}"
  key_name      = "${var.key_name}"

  security_groups = [
    "${aws_security_group.zookeeper.id}",
    "${var.additional_security_group_ids}",
  ]

  user_data                   = "${data.template_file.user_data_zookeeper.*.rendered[count.index]}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.kafka_profile.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "zk" {
  count                     = "${var.zookeeper_cluster_size}"
  availability_zones        = "${list(element(var.availability_zones, count.index))}"
  name                      = "${var.environment}_zookeeper-asg_${count.index+1}"
  max_size                  = "1"
  min_size                  = "1"
  desired_capacity          = "1"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.zookeeper.*.id[count.index]}"
  vpc_zone_identifier       = ["${list(element(var.subnet_ids, count.index))}"]
  default_cooldown          = 100

  tag {
    key                 = "Name"
    value               = "${var.environment}_zookeeper_${count.index}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Description"
    value               = "Zookeeper application cluster for ${var.environment} environment"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }
}
