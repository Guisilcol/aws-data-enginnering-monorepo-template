# /modules/tf-aws-glue-catalog/outputs.tf

output "database_name" {
  description = "The name of the created Glue database."
  value       = aws_glue_catalog_database.this.name
}

output "table_names" {
  description = "A list of names of the created Glue tables."
  value       = [for table in aws_glue_catalog_table.this : table.name]
}