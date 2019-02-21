data "template_file" "user_data_kafka" {
  count    = "${var.kafka_cluster_size}"
  template = "${file("${path.module}/kafka_install.tpl")}"

  vars {
    broker_id              = "${count.index}"
    zookeeper_cluster_size = "${var.zookeeper_cluster_size}"
    hosted_zone_id         = "${var.hosted_zone_id}"
    hosted_zone_name       = "${var.hosted_zone_name}"
    environment            = "${var.environment}"
  }
}

data "template_file" "user_data_zookeeper" {
  count    = "${var.zookeeper_cluster_size}"
  template = "${file("${path.module}/zookeeper_install.tpl")}"

  vars {
    node_id          = "${count.index+1}"
    hosted_zone_id   = "${var.hosted_zone_id}"
    hosted_zone_name = "${var.hosted_zone_name}"
    cluster_size     = "${var.zookeeper_cluster_size}"
  }
}
