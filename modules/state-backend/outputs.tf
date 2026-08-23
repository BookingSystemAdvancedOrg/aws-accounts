output "bucket_name" {
  description = "S3 bucket the customer's own Terraform (their dev/prod app infra) should use as its state backend in this account."
  value       = aws_s3_bucket.tfstate.id
}

output "bucket_arn" {
  value = aws_s3_bucket.tfstate.arn
}
