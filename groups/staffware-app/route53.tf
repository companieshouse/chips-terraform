resource "aws_route53_record" "ewf_alb_internal" {
  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = var.application
  type    = "A"

  alias {
    name                   = module.iprocess_app_internal_alb.this_lb_dns_name
    zone_id                = module.iprocess_app_internal_alb.this_lb_zone_id
    evaluate_target_health = true
  }
}