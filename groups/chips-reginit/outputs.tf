output "dns_names" {
  value = aws_route53_record.reginit_dns.*.name
}
