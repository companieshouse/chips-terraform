resource "aws_route53_record" "staffware_rds" {
  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = "${var.name}db"
  type    = "CNAME"
  ttl     = "300"
  records = [module.staffware_rds.this_db_instance_address]
}
