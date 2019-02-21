variable "vpc_id" {}

variable "ingress_allowed_cidrs" {
  type = "list"
}

variable "additional_security_group_ids" {
  type    = "list"
  default = []
}

variable "key_name" {}

variable "region" {
  default = "us-east-1"
}

variable "subnet_ids" {
  type = "list"
}

variable "public_subnet_ids" {
  type = "list"
}

variable "availability_zones" {
  type = "list"
}

variable "company_id" {}
variable "environment" {}

variable "amis" {
  type = "map"

  default = {
    us-east-1 = "ami-97785bed"
  }
}

variable "zookeeper_instance_type" {
  default = "t2.micro"
}

variable "kafka_instance_type" {
  default = "t2.small"
}

variable "kafka_cluster_size" {
  default = "3"
}

variable "zookeeper_cluster_size" {
  default = "3"
}

variable "hosted_zone_id" {}
variable "hosted_zone_name" {}

variable "kafka_disk_size" {
  default = "250"
}
