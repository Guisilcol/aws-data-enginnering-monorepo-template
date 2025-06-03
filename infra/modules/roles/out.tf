output "iam_roles" {
  description = "A map of the created IAM roles, keyed by their filename-derived names."
  value = {
    for role_key, role_object in aws_iam_role.this : role_key => {
      arn  = role_object.arn
      id   = role_object.id
      name = role_object.name
      # unique_id = role_object.unique_id # another useful attribute
    }
  }
}

output "iam_role_arns" {
  description = "A map of IAM role ARNs, keyed by their filename-derived names."
  value = {
    for role_key, role_object in aws_iam_role.this : role_key => role_object.arn
  }
}

output "iam_role_names" {
  description = "A map of IAM role names, keyed by their filename-derived names."
  value = {
    for role_key, role_object in aws_iam_role.this : role_key => role_object.name
  }
}