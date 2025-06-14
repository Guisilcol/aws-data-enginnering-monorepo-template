# Usage example

`terraform
module "ec2_s3_role" {
  # Path to the module directory.
  source = "./modules/iam-role-module"

  # (Input) Define the name for this specific role.
  role_name = "ec2-s3-reader-role"

  # (Input) Define the trust policy that allows EC2 instances to assume this role.
  assume_role_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  # (Input) Define the permissions policy for the role.
  # This policy grants read-only access to a specific S3 bucket.
  role_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::my-example-bucket",
          "arn:aws:s3:::my-example-bucket/*"
        ]
      }
    ]
  })
}

´