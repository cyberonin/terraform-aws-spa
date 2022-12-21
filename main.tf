locals {
  name      = "${var.label_namespace}-${var.label_env}-${var.label_app}"
  origin_id = "${var.label_namespace}-${var.label_env}-${var.label_app}-origin-id"

  default_tags = {
    Project     = "${var.label_namespace}"
    Environment = "${var.label_env}"
    Name        = "${var.label_app}"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "aws_cloudfront_origin_access_identity" "spa_origin_access_identity" {}

resource "aws_s3_bucket" "spa_bucket" {
  bucket        = "${local.name}-bucket"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = local.tags
}

resource "aws_s3_bucket_acl" "spa_bucket_acl" {
  bucket = aws_s3_bucket.spa_bucket.id
  acl    = "private"
}

data "aws_iam_policy_document" "spa_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.spa_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.spa_origin_access_identity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.spa_bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.spa_origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "spa_bucket_policy" {
  bucket = aws_s3_bucket.spa_bucket.id
  policy = data.aws_iam_policy_document.spa_s3_policy.json
}

resource "aws_cloudfront_distribution" "spa_cloudfront_distribution" {
  depends_on = [
    aws_s3_bucket.spa_bucket
  ]

  comment = "${local.name}-cf-dist"

  origin {
    domain_name = aws_s3_bucket.spa_bucket.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.spa_origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  price_class = var.distribution_price_class
  aliases     = var.domain_names


  default_cache_behavior {
    viewer_protocol_policy = var.distribution_viewer_protocal_policy
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.origin_id
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = 0
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.tags
}
