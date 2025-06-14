
variable "region" {
    description = "AWS region to deploy the infrastructure"
    type        = string
    default     = "us-east-2"
  
}

variable "template_values" {
    description = "Template values for the infrastructure modules"
    type        = map(string)
    default     = {}
}