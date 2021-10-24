# cyo-prod-fontend-spa

locals {
  name      = "${var.label_namespace}-${var.label_env}-${var.label_app}-spa"
  origin_id = "${var.label_namespace}-${var.label_env}-${var.label_app}-spa-origin-id"
}

resource "aws_cloudfront_origin_access_identity" "spa_origin_access_identity" {}

resource "aws_s3_bucket" "spa_bucket" {
  bucket        = "${local.name}-bucket"
  acl           = "private"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

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
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.origin_id
    compress               = true

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    forwarded_values {
      query_string = var.basic_auth_enabled ? true : false

      cookies {
        forward = var.basic_auth_enabled ? "all" : "none"
      }
    }

    dynamic "lambda_function_association" {
      for_each = var.basic_auth_enabled ? [0] : []
      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.basic_auth_function[0].qualified_arn
        include_body = false
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

# Lambda
# ------

resource "aws_iam_role" "basic_auth_function_role" {
  count    = var.basic_auth_enabled ? 1 : 0
  name     = "${local.name}-basic-auth-function-role"
  provider = aws.us_east_1

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Service": [
         "lambda.amazonaws.com",
         "edgelambda.amazonaws.com"
       ]
     },
     "Action": "sts:AssumeRole"
   }
 ]
}
EOF
}

# data "aws_iam_policy_document" "lambda_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
#     }
#   }
# }
# resource "aws_iam_role" "basic_auth_function_role" {
#   name               = "${local.name}-basic-auth-function-role"
#   assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
#   provider           = aws.us_east_1
# }

resource "aws_iam_role_policy" "basic_auth_function_role_policy" {
  count    = var.basic_auth_enabled ? 1 : 0
  name     = "${local.name}-basic-auth-function-role-policy"
  role     = aws_iam_role.basic_auth_function_role[0].id
  provider = aws.us_east_1

  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*"
   }
 ]
}
EOF
}

provider "aws" {
  alias                   = "us_east_1"
  region                  = "us-east-1"
  profile                 = var.aws_profile
  shared_credentials_file = var.aws_shared_credentials_file
}


data "template_file" "basic_auth_function" {
  template = file("${path.module}/basic-auth.js")
  vars = {
    username = var.username
    password = var.password
  }
}

data "archive_file" "basic_auth_function_zip" {
  type        = "zip"
  output_path = "${path.module}/basic-auth.zip"

  source {
    content  = data.template_file.basic_auth_function.rendered
    filename = "basic-auth.js"
  }
}

resource "aws_lambda_function" "basic_auth_function" {
  count            = var.basic_auth_enabled ? 1 : 0
  function_name    = "${local.name}-basic-auth-function"
  filename         = data.archive_file.basic_auth_function_zip.output_path
  role             = aws_iam_role.basic_auth_function_role[0].arn
  handler          = "basic-auth.handler"
  source_code_hash = data.archive_file.basic_auth_function_zip.output_base64sha256
  runtime          = "nodejs14.x"
  publish          = true
  provider         = aws.us_east_1
}

resource "time_sleep" "wait_30_seconds" {
  depends_on       = [aws_lambda_function.basic_auth_function]
  destroy_duration = "1200s"
}

resource "null_resource" "next" {
  depends_on = [time_sleep.wait_30_seconds]
}
