output "bucket_ids" {
  description = "A map of bucket names to their corresponding IDs."
  value = {
    for k, v in aws_s3_bucket.this : k => v.id
  }
}

output "bucket_arns" {
  description = "A map of bucket names to their corresponding ARNs."
  value = {
    for k, v in aws_s3_bucket.this : k => v.arn
  }
}