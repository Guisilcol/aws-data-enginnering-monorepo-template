module "master_role" {
  source = "./modules/role"

  role_name = "master-role"

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