module "bronze_layer" {
  source = "./modules/catalog"

  database_name           = "bronze_layer"
  s3_bucket_name          = module.bronze_layer_bucket.bucket_id
  tables_definition_path  = "./definitions/tables/bronze_layer"

  depends_on = [ module.bronze_layer_bucket ]
}