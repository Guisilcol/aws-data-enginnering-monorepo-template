variable "database_name" {
  type        = string
  description = "The name of the Glue Catalog database to be created."
}

variable "s3_bucket_name" {
  type        = string
  description = "The name of the S3 bucket where the table data is stored."
}

variable "tables_definition_path" {
  type        = string
  description = "The path to the directory containing the YAML table definitions."
}