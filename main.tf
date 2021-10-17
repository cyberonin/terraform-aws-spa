# cyo-prod-fontend-spa

locals {
  name      = "${var.label_namespace}-${var.label_env}-${var.label_app}-spa"
  origin_id = "${var.label_namespace}-${var.label_env}-${var.label_app}-spa-origin-id"
}

resource "aws_cloudfront_origin_access_identity" "spa_origin_access_identity" {}

resource "aws_s3_bucket" "spa_bucket" {
  bucket = "${local.name}-bucket"
  acl    = "private"

  tags = {
    "Project"     = "${var.label_namespace}"
    "Environment" = "${var.label_env}"
    "Name"        = "${local.name}-bucket"
  }
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
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.origin_id
    compress               = true

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code            = "403"
    error_caching_min_ttl = 0
    response_code         = "200"
    response_page_path    = "/index.html"
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

  tags = {
    "Project"     = "${var.label_namespace}"
    "Environment" = "${var.label_env}"
    "Name"        = "${local.name}-cf-dist"
  }
}

