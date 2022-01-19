output "rds_address" {
  value = aws_route53_record.chips_rds.fqdn
}
