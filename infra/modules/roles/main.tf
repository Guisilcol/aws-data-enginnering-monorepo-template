locals {
  # 1. Find all YAML/YML files in the specified directory path.
  # fileset(path, pattern) returns a set of all files in the given path that match the glob pattern.
  yaml_files = fileset(var.yaml_files_path, "**/*.{yaml,yml}")

  # 2. Process each YAML file.
  # We create a map where each key is the derived role name (filename without extension)
  # and the value contains the parsed content of the YAML file.
  roles_data = {
    for file_path in local.yaml_files :
    # Role name is derived from the filename by removing .yaml or .yml suffix.
    # Example: "my-role.yaml" -> "my-role"
    trimsuffix(trimsuffix(basename(file_path), ".yaml"), ".yml") => {
      # file(path) reads the content of the file at the given path.
      content_string = file(format("%s/%s", var.yaml_files_path, file_path))
      # yamldecode(string) parses a YAML string and returns a data structure.
      parsed_content = yamldecode(file(format("%s/%s", var.yaml_files_path, file_path)))
      # Keep the original filename for reference or logging if needed.
      original_filename = basename(file_path)
    }
  }

  # 3. Flatten inline policies for resource creation.
  # This creates a flat list of all inline policies from all roles,
  # making it easier to use with for_each in aws_iam_role_policy.
  flattened_inline_policies = flatten([
    for role_name_key, role_config in local.roles_data : [ # role_name_key is the filename-derived name
      for policy_def in lookup(role_config.parsed_content, "inline_policies", []) : {
        role_map_key    = role_name_key # Key to link back to the aws_iam_role.this map
        policy_name     = policy_def.name
        # jsonencode() converts a Terraform expression result to a JSON string.
        # The policy itself within YAML can be a map/list structure.
        policy_document = jsonencode(policy_def.policy)
      } if lookup(role_config.parsed_content, "inline_policies", null) != null # Process only if inline_policies exist
    ]
  ])

  # 4. Flatten managed policy attachments.
  # Similar to inline policies, this creates a flat list for aws_iam_role_policy_attachment.
  flattened_managed_policies = flatten([
    for role_name_key, role_config in local.roles_data : [
      for policy_arn_val in lookup(role_config.parsed_content, "managed_policy_arns", []) : {
        role_map_key = role_name_key
        policy_arn   = policy_arn_val
      } if lookup(role_config.parsed_content, "managed_policy_arns", null) != null # Process only if managed_policy_arns exist
    ]
  ])
}

# --- IAM Role Creation ---
# Create an IAM role for each YAML file processed.
# for_each iterates over the local.roles_data map.
resource "aws_iam_role" "this" {
  for_each = local.roles_data # each.key will be the filename-derived role name (e.g., "my-web-server")
                              # each.value will be the object containing parsed_content

  name               = each.key # Role name is the filename (without extension)
  description        = lookup(each.value.parsed_content, "description", "IAM role managed by Terraform module.")
  assume_role_policy = jsonencode(each.value.parsed_content.assume_role_policy) # Must be a JSON string
  permissions_boundary = lookup(each.value.parsed_content, "permissions_boundary", null)

  tags = merge(
    {
      "Name"      = each.key # Default tag for the role name
      "ManagedBy" = "Terraform-IAM-Module"
    },
    lookup(each.value.parsed_content, "tags", {}) # Merge any custom tags from YAML
  )
}

# --- Inline Policy Creation ---
# Create IAM role inline policies if defined in the YAML.
resource "aws_iam_role_policy" "inline" {
  # Create a unique key for for_each: "role_map_key.policy_name"
  # This ensures that each inline policy for each role gets its own resource instance.
  for_each = {
    for pol in local.flattened_inline_policies :
    "${pol.role_map_key}.${pol.policy_name}" => pol
  }

  name   = each.value.policy_name
  # The 'role' attribute requires the NAME of the IAM role.
  # aws_iam_role.this[each.value.role_map_key] refers to the aws_iam_role resource instance.
  # .name gives its actual name attribute.
  role   = aws_iam_role.this[each.value.role_map_key].name
  policy = each.value.policy_document # Already a JSON string from local.flattened_inline_policies
}

# --- Managed Policy Attachment ---
# Attach managed IAM policies if defined in the YAML.
resource "aws_iam_role_policy_attachment" "managed" {
  # Create a unique key for for_each using role_map_key and a hash of the policy ARN.
  # This handles multiple managed policies per role and ensures unique keys for for_each.
  for_each = {
    for attachment in local.flattened_managed_policies :
    "${attachment.role_map_key}.${md5(attachment.policy_arn)}" => attachment
  }

  role       = aws_iam_role.this[each.value.role_map_key].name
  policy_arn = each.value.policy_arn
}