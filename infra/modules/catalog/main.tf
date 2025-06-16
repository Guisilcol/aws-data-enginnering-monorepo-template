# Lê e processa todos os arquivos YAML do diretório especificado.
locals {
  # Encontra todos os arquivos que terminam com .yaml ou .yml no diretório.
  table_files = fileset(var.tables_definition_path, "**/*.{yaml,yml}")

  # Decodifica cada arquivo YAML em um objeto Terraform.
  # A chave para cada tabela será o nome do arquivo.
  all_tables = {
    for file in local.table_files :
    file => yamldecode(file("${var.tables_definition_path}/${file}"))
  }

  # Filtra para criar um mapa contendo apenas as tabelas ICEBERG.
  iceberg_tables = {
    for k, v in local.all_tables : k => v if upper(v.table_type) == "ICEBERG"
  }

  # Filtra para criar um mapa contendo todas as outras tabelas (externas padrão).
  external_tables = {
    for k, v in local.all_tables : k => v if upper(v.table_type) != "ICEBERG"
  }
}

# Cria o banco de dados no AWS Glue Catalog.
resource "aws_glue_catalog_database" "this" {
  name         = var.database_name
  location_uri = "s3://${var.s3_bucket_name}"
}


#################################################
#                TABELAS ICEBERG                #
#################################################
# Cria uma tabela no Glue Catalog para cada tabela ICEBERG definida.
resource "aws_glue_catalog_table" "iceberg" {
  for_each = local.iceberg_tables

  # Informações básicas da tabela.
  name          = each.value.name
  database_name = aws_glue_catalog_database.this.name
  description   = each.value.description
  
  # O tipo da tabela no Glue é 'EXTERNAL_TABLE' mesmo para tabelas Iceberg.
  table_type    = "EXTERNAL_TABLE"

  open_table_format_input {
    iceberg_input {
      metadata_operation = "CREATE"
      version            = "2"
    }
  }

  parameters = { "format-version" = "2" }

  storage_descriptor {
    location = "${aws_glue_catalog_database.this.location_uri}/${each.value.name}"

    dynamic "columns" {
      for_each = each.value.schema
      content {
        name    = columns.value.name
        type    = columns.value.type
        comment = columns.value.comment
      }
    }
  }

  dynamic "partition_keys" {
    for_each = try(each.value.partitions, [])
    content {
      name    = partition_keys.value.name
      type    = partition_keys.value.type
      comment = partition_keys.value.comment
    }
  }
}


#################################################
#             TABELAS EXTERNAS PADRÃO           #
#################################################
# Cria uma tabela no Glue Catalog para cada tabela externa padrão (Hive, Parquet, etc.).
resource "aws_glue_catalog_table" "external" {
  for_each = local.external_tables

  # Informações básicas da tabela.
  name          = each.value.name
  database_name = aws_glue_catalog_database.this.name
  description   = each.value.description
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"            = "TRUE"
    "parquet.compression" = "SNAPPY"
    "table_type"          = "hive" # Ajuda a classificar a tabela para os mecanismos de consulta.
    "ignore.partition.filtering.for.full.table.scan" = "true"
  }

  storage_descriptor {
    location      = "${aws_glue_catalog_database.this.location_uri}/${each.value.name}"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    
    ser_de_info {
      name                  = "parquet-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    # Gera os blocos de colunas.
    dynamic "columns" {
      for_each = each.value.schema
      content {
        name    = columns.value.name
        type    = columns.value.type
        comment = columns.value.comment
      }
    }
  }

  # Gera os blocos de chaves de partição.
  dynamic "partition_keys" {
    for_each = try(each.value.partitions, [])
    content {
      name    = partition_keys.value.name
      type    = partition_keys.value.type
      comment = partition_keys.value.comment
    }
  }
}