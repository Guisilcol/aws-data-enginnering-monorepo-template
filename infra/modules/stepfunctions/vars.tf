# variables.tf

variable "yamls_directory" {
  type        = string
  description = "The path to the directory containing the State Machine .yaml configuration files. The path should be relative to where you run terraform."
}

variable "template_variables" {
  type        = map(any)
  description = "A map of values to be substituted into the state machine definition JSON files via the templatefile() function."
  default     = {}
}