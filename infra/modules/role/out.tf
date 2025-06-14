# outputs.tf

# The Amazon Resource Name (ARN) of the role.
output "role_arn" {
  description = "The ARN of the created IAM role."
  value       = aws_iam_role.this.arn
}

# The name of the role.
output "role_name" {
  description = "The name of the created IAM role."
  value       = aws_iam_role.this.name
}