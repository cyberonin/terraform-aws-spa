output "spa_bucket_id" {
  value = aws_s3_bucket.default.id
}

output "spa_bucket_arn" {
  value = aws_s3_bucket.default.arn
}

output "spa_bucket_policy" {
  value = data.aws_iam_policy_document.s3_policy.json
}

