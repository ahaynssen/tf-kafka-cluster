module "kafka" {
  source = "../"
  company_id = ""
  environment = ""

  availability_zones = ""
  key_name = ""

  # networking
  vpc_id = ""
  subnet_ids = ""
  public_subnet_ids = ""
  ingress_allowed_cidrs = ""

  # dns
  hosted_zone_id = ""
  hosted_zone_name = ""
}