output "dns_names" {
  value = aws_route53_record.oem_dns.*.name
}
