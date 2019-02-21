resource "aws_elb" "kafka" {
  name            = "${var.environment}-kafka"
  subnets         = ["${var.public_subnet_ids}"]
  security_groups = ["${aws_security_group.kafka.id}"]

  "listener" {
    instance_port     = 9092
    instance_protocol = "tcp"
    lb_port           = 9092
    lb_protocol       = "tcp"
  }

  cross_zone_load_balancing = true
  internal                  = false

  tags {
    Name        = "${var.environment}_kafka"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "kafka" {
  name    = "kafka"
  type    = "A"
  zone_id = "${var.hosted_zone_id}"

  alias {
    evaluate_target_health = false
    name                   = "${aws_elb.kafka.dns_name}"
    zone_id                = "${aws_elb.kafka.zone_id}"
  }
}
