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

  # cors_rule {
  #   allowed_headers = ["*"]
  #   allowed_methods = ["GET", "HEAD"]
  #   allowed_origins = ["*"]
  #   expose_headers  = ["ETag"]
  # }
}

resource "aws_s3_bucket_acl" "spa_bucket_acl" {
  bucket = aws_s3_bucket.spa_bucket.id
  acl    = "private"
}

data "aws_iam_policy_document" "spa_s3_policy" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.spa_bucket.arn}/*"]
    actions   = ["s3:GetObject"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${aws_cloudfront_distribution.spa_cloudfront_distribution.arn}"]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "spa_bucket_policy" {
  bucket = aws_s3_bucket.spa_bucket.id
  policy = data.aws_iam_policy_document.spa_s3_policy.json
}


data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "security_headers_policy" {
  name = "Managed-CORS-with-preflight-and-SecurityHeadersPolicy"
}

resource "aws_cloudfront_origin_access_control" "spa_cloudfront_origin_access_control" {
  name                              = local.origin_id
  description                       = local.origin_id
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "spa_cloudfront_distribution" {
  depends_on = [
    aws_s3_bucket.spa_bucket
  ]

  comment = "${local.name}-cf-dist"

  origin {
    domain_name              = aws_s3_bucket.spa_bucket.bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.spa_cloudfront_origin_access_control.id

    # s3_origin_config {
    #   origin_access_identity = aws_cloudfront_origin_access_identity.spa_origin_access_identity.cloudfront_access_identity_path
    # }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  price_class = var.distribution_price_class
  aliases     = var.domain_names


  default_cache_behavior {
    viewer_protocol_policy     = var.distribution_viewer_protocal_policy
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = local.origin_id
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers_policy.id
  }

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = 0
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_code            = "403"
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
