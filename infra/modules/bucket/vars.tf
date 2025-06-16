variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "block_public_acls" {
  description = "Whether to block public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether to block public bucket policies for this bucket."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether to ignore public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether to restrict public bucket policies for this bucket."
  type        = bool
  default     = true
}

variable "versioning_status" {
  description = "The versioning status of the bucket. Can be 'Enabled', 'Disabled', or 'Suspended'."
  type        = string
  default     = "Disabled"
}

variable "lifecycle_rules" {
  description = "A list of lifecycle rules for the bucket."
  type        = any
  default     = []
}