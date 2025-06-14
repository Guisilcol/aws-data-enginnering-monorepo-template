module "source_code_bucket" {
  source = "./modules/bucket"

  bucket_name = "source-code-bucket"
  versioning_status = "Disabled"
  lifecycle_rules = []
  tags = {}
}

module "bronze_layer_bucket" {
  source = "./modules/bucket"

  bucket_name = "bronze-layer-bucket"
  versioning_status = "Disabled"
  lifecycle_rules = []
  tags = {}
}