output "database_name" {
  description = "The name of the created Glue database."
  value       = aws_glue_catalog_database.this.name
}

output "iceberg_tables" {
  description = "A list of names of the created Glue tables."
  value       = [for table in aws_glue_catalog_table.iceberg : table.name]
}

output "external_tables" {
  description = "A list of names of the created Glue external tables."
  value       = [for table in aws_glue_catalog_table.external : table.name]
  
}