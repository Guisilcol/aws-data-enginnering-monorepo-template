
variable "region" {
    description = "AWS region to deploy the infrastructure"
    type        = string
    default     = "us-east-2"
  
}

variable "aws_cli_profile" {
    description = "AWS CLI profile to use for deployment"
    type        = string
    default     = "default"
}

variable "template_values" {
    description = "Template values for the infrastructure modules"
    type        = map(string)
    default     = {}
}