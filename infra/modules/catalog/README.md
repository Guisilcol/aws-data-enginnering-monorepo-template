# Usage example

## To create a module: 
`terraform
module "glue_catalog" {
  source = "./modules/tf-aws-glue-catalog"

  database_name           = "my_data_lake_db"
  s3_bucket_name          = "my-data-lake-bucket-12345" # Change to your bucket name
  tables_definition_path  = "${path.module}/examples/tables"
}
´

## YAML Definition example: 

### External table

`yaml
name: "customers"
description: "Table for storing customer data."
table_type: "EXTERNAL_TABLE"
schema:
  - name: "customer_id"
    type: "string"
    comment: "Unique identifier for the customer."
  - name: "first_name"
    type: "string"
    comment: "Customer's first name."
  - name: "last_name"
    type: "string"
    comment: "Customer's last name."
  - name: "email"
    type: "string"
    comment: "Customer's email address."
partitions:
  - name: "registration_date"
    type: "date"
    comment: "Date when the customer registered."
`

### ICEBERG TABLE 

`yaml
name: "products"
description: "Table for storing product information."
table_type: "ICEBERG"
schema:
  - name: "product_id"
    type: "string"
    comment: "Unique identifier for the product."
  - name: "product_name"
    type: "string"
    comment: "Name of the product."
  - name: "price"
    type: "decimal(10, 2)"
    comment: "Price of the product."
  - name: "category"
    type: "string"
    comment: "Product category."
`