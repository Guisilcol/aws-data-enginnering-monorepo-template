variable "definitions_directory" {
  type        = string
  description = "The directory path containing the Step Function definition YAML files."
}

variable "role_arn" {
  type        = string
  description = "The ARN of the IAM role to be assigned to the Step Functions."
}