module "source_code_bucket" {
  source = "./modules/bucket"

  bucket_name = "source-code-${local.account_id}"
  versioning_status = "Disabled"
  lifecycle_rules = []
  tags = {}
}

module "athena_assets_bucket" {
  source = "./modules/bucket"

  bucket_name = "athena-assets-${local.account_id}"
  versioning_status = "Disabled"
  lifecycle_rules = []
  tags = {}
}

module "bronze_layer_bucket" {
  source = "./modules/bucket"

  bucket_name = "bronze-layer-${local.account_id}"
  versioning_status = "Disabled"
  lifecycle_rules = []
  tags = {}
}