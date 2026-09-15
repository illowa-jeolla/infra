output "certificate_arns" {
  description = "ACM certificate ARNs keyed by domain name."
  value = {
    for domain_name, certificate in aws_acm_certificate.this :
    domain_name => certificate.arn
  }
}

output "statuses" {
  description = "Current ACM certificate statuses keyed by domain name."
  value = {
    for domain_name, certificate in aws_acm_certificate.this :
    domain_name => certificate.status
  }
}

output "dns_validation_records" {
  description = "CNAME records that must be added at the external DNS provider."
  value = merge([
    for certificate in values(aws_acm_certificate.this) : {
      for option in certificate.domain_validation_options : option.domain_name => {
        name  = option.resource_record_name
        type  = option.resource_record_type
        value = option.resource_record_value
      }
    }
  ]...)
}
