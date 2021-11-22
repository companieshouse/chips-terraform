output "db_dns_names" {
  value = aws_route53_record.db_dns.*.name
}
