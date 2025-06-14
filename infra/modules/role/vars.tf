# variables.tf

# The desired name for the IAM Role.
variable "role_name" {
  description = "The name of the IAM role."
  type        = string
}

# The inline policy document in JSON format.
variable "role_policy_json" {
  description = "The policy document for the IAM role in JSON format."
  type        = string
}

# The trust relationship policy document in JSON format.
variable "assume_role_policy_json" {
  description = "The trust relationship policy document for the IAM role in JSON format."
  type        = string
}