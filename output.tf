output "spa_bucket_name" {
  description = "Name of the created spa S3 bucket"
  value       = aws_s3_bucket.spa_bucket.id
}

output "spa_bucket_arn" {
  description = "ARN of the created spa S3 bucket"
  value       = aws_s3_bucket.spa_bucket.arn
}

output "spa_distribution_id" {
  description = "ID of the created spa CloudFront distribution"
  value       = aws_cloudfront_distribution.spa_cloudfront_distribution.id
}

output "spa_distribution_arn" {
  description = "ARN of the created spa CloudFront distribution"
  value       = aws_cloudfront_distribution.spa_cloudfront_distribution.arn
}

output "spa_distribution_domain" {
  description = "Domain of the created spa CloudFront distribution, eg. d604721fxaaqy9.cloudfront.net."
  value       = aws_cloudfront_distribution.spa_cloudfront_distribution.domain_name
}
