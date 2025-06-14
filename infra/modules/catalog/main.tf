# /modules/tf-aws-glue-catalog/main.tf

# Read and parse all YAML files from the specified directory.
locals {
  # Find all files ending with .yaml or .yml in the specified directory.
  table_files = fileset(var.tables_definition_path, "**/*.{yaml,yml}")

  # Decode each YAML file content into a Terraform object.
  # The key for each table will be its filename.
  tables = {
    for file in local.table_files :
    file => yamldecode(file("${var.tables_definition_path}/${file}"))
  }
}

# Create the AWS Glue Catalog database.
resource "aws_glue_catalog_database" "this" {
  name = var.database_name
  location_uri = "s3://${var.s3_bucket_name}"
}

# Create a Glue Catalog table for each parsed YAML file.
resource "aws_glue_catalog_table" "this" {
  for_each = local.tables

  # Basic table information.
  name          = each.value.name
  database_name = aws_glue_catalog_database.this.name
  description   = each.value.description
  table_type    = upper(each.value.table_type) == "ICEBERG" ? "ICEBERG" : "EXTERNAL_TABLE"

  # Table parameters, required for Iceberg tables.
  parameters = upper(each.value.table_type) == "ICEBERG" ? {
    "table_type"                 = "ICEBERG"
    "metadata_location"          = "${aws_glue_catalog_database.this.location_uri}/${each.value.name}/metadata/metadata.json"
    "format-version"             = "2"
    "write.parquet.compression-codec" = "snappy"
    } : {
    "EXTERNAL"              = "TRUE"
    "parquet.compression"   = "SNAPPY"
  }

  # Define storage properties.
  storage_descriptor {
    # Set the storage location for the table's data.
    location = "${aws_glue_catalog_database.this.location_uri}/${each.value.name}"

    # Define the input and output formats for Parquet.
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    # Define the SerDe for Parquet.
    ser_de_info {
      name                  = "parquet-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    # CORRECTED: Use a 'dynamic' block to generate 'columns' blocks.
    # This iterates over the schema from the YAML and creates a 'columns' block for each item.
    dynamic "columns" {
      for_each = each.value.schema
      content {
        name    = columns.value.name
        type    = columns.value.type
        comment = columns.value.comment
      }
    }
  }

  # CORRECTED: Use a 'dynamic' block to generate 'partition_keys' blocks.
  # This iterates over the partitions from the YAML and creates a 'partition_keys' block for each.
  # The 'try' function gracefully handles cases where 'partitions' is not defined in the YAML.
  dynamic "partition_keys" {
    for_each = try(each.value.partitions, [])
    content {
      name    = partition_keys.value.name
      type    = partition_keys.value.type
      comment = partition_keys.value.comment
    }
  }
}