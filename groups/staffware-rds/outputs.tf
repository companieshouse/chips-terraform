output "rds_address" {
  value = aws_route53_record.staffware_rds.fqdn
}
