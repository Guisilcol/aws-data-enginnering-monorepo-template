# Usage example

`terraform
module "my_s3_bucket" {
  source = "./s3-bucket-module"

  bucket_name = "my-unique-application-bucket"
  tags = {
    Environment = "Production"
    Project     = "MyApplication"
  }

  versioning_status = "Enabled"

  lifecycle_rules = [
    {
      id      = "log"
      enabled = true
      filter = {
        prefix = "log/"
      }

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 90
      }
    }
  ]
}
´