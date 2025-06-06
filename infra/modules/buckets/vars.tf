variable "yamls_directory" {
  type        = string
  description = "The path to the directory containing the S3 bucket YAML configuration files."
}

variable "template_values" {
  type        = map(string)
  description = "A map of key-value pairs to be used for substituting placeholders in the YAML files."
  default     = {}
}