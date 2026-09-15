resource "aws_acm_certificate" "this" {
  for_each = var.domain_names

  domain_name       = each.value
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = each.value
  })
}

moved {
  from = aws_acm_certificate.this
  to   = aws_acm_certificate.this["api.cltrmp.cloud"]
}
