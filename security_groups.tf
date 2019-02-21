resource "aws_security_group" "kafka" {
  name        = "${var.environment}_kafka_security_group"
  description = "Allow kafka traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["${flatten(var.ingress_allowed_cidrs)}"]
  }

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["${flatten(var.ingress_allowed_cidrs)}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}_kafka_security_group"
  }
}

resource "aws_security_group" "zookeeper" {
  name        = "${var.environment}_zookeeper_security_group"
  description = "Allow zookeeper traffic"
  vpc_id      = "${var.vpc_id}"

  # port 31995 as well maybe
  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = ["${flatten(var.ingress_allowed_cidrs)}"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}_zookeeper_security_group"
  }
}
