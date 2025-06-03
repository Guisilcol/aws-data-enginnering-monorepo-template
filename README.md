# Terraform AWS IAM Roles from YAML Module

This Terraform module creates AWS IAM Roles based on definitions provided in YAML files within a specified directory. Each YAML file corresponds to a single IAM role, and the filename (excluding the extension) is used as the role name.

## Features

-   Creates IAM roles from YAML definitions.
-   Supports inline policies.
-   Supports attaching existing managed policies (AWS or customer-managed).
-   Supports permissions boundaries.
-   Allows custom tags.
-   Role names are derived from YAML filenames.

## YAML File Structure

Each `.yaml` or `.yml` file in the `yaml_files_path` directory should define a single role. Below is an example structure:

```yaml
# Filename: example-role.yaml (this will create a role named "example-role")

# (Required) Assume Role Policy Document (Trust Relationship)
# Defines which principals can assume this role.
assume_role_policy:
  Version: "2012-10-17"
  Statement:
    - Effect: "Allow"
      Principal:
        Service: "ec2.amazonaws.com"
      Action: "sts:AssumeRole"
    # - Effect: "Allow" # Example for another principal
    #   Principal:
    #     AWS: "arn:aws:iam::123456789012:root"
    #   Action: "sts:AssumeRole"

# (Optional) Description for the IAM role.
description: "This is an example role for EC2 instances with specific S3 access."

# (Optional) Inline policies. This is a list of policies.
# Each policy needs a 'name' (unique within the role) and a 'policy' document.
inline_policies:
  - name: "S3BucketAccess"
    policy:
      Version: "2012-10-17"
      Statement:
        - Effect: "Allow"
          Action:
            - "s3:GetObject"
            - "s3:ListBucket"
          Resource:
            - "arn:aws:s3:::my-example-bucket"
            - "arn:aws:s3:::my-example-bucket/*"
  - name: "CloudWatchLogsWrite"
    policy:
      Version: "2012-10-17"
      Statement:
        - Effect: "Allow"
          Action:
            - "logs:CreateLogGroup"
            - "logs:CreateLogStream"
            - "logs:PutLogEvents"
          Resource: "arn:aws:logs:*:*:*"

# (Optional) List of ARNs for managed policies to attach to the role.
managed_policy_arns:
  - "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  # - "arn:aws:iam::123456789012:policy/MyCustomManagedPolicy"

# (Optional) ARN of the policy to use as a permissions boundary for the role.
permissions_boundary: "arn:aws:iam::123456789012:policy/MyPermissionsBoundaryPolicy" # Replace with your boundary policy ARN

# (Optional) Tags to apply to the IAM role.
tags:
  Environment: "development"
  Project: "WebAppX"
  Owner: "TeamAlpha"