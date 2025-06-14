# main.tf

# Creates the IAM Role.
resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy_json
}

# Attaches an inline policy to the IAM Role.
resource "aws_iam_role_policy" "this" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.this.id
  policy = var.role_policy_json
}