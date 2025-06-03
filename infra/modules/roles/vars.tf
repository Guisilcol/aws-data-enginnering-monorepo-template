variable "yaml_files_path" {
  description = "The path to the directory containing YAML files that define IAM roles. Each YAML file corresponds to one role."
  type        = string
  # You might want to add validation for the path if needed,
  # but Terraform will error out if the path is invalid during file operations.
}