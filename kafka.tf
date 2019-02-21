resource "aws_iam_instance_profile" "kafka_profile" {
  name = "${var.environment}_kafka_profile"
  role = "${aws_iam_role.kafka.name}"
}

resource "aws_launch_configuration" "kafka_lc" {
  count         = "${var.kafka_cluster_size}"
  image_id      = "${lookup(var.amis, var.region)}"
  instance_type = "${var.kafka_instance_type}"
  key_name      = "${var.key_name}"

  security_groups = [
    "${aws_security_group.kafka.id}",
    "${var.additional_security_group_ids}",
  ]

  user_data                   = "${data.template_file.user_data_kafka.*.rendered[count.index]}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.kafka_profile.id}"

  root_block_device {
    volume_size = "${var.kafka_disk_size}"
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kafka_asg" {
  count                     = "${var.kafka_cluster_size}"
  availability_zones        = "${list(element(var.availability_zones, count.index))}"
  name                      = "${var.environment}_kafka-asg_${count.index}"
  max_size                  = "1"
  min_size                  = "1"
  desired_capacity          = "1"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.kafka_lc.*.id[count.index]}"
  vpc_zone_identifier       = ["${list(element(var.private_subnet_ids, count.index))}"]
  default_cooldown          = 100
  load_balancers            = ["${aws_elb.kafka.id}"]

  tag {
    key                 = "Name"
    value               = "${var.environment}_kafka_${count.index}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Description"
    value               = "Kafka application cluster for ${var.environment} environment"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }
}
