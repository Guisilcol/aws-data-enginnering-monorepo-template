# 1. Find all YAML files, then read, template, and decode them into a map.
locals {
  # Find all files ending in .yaml or .yml in the specified directory.
  yaml_files = fileset(var.yamls_directory, "**/{*.yaml,*.yml}")

  # Create a map where the key is the bucket name (from the filename)
  # and the value is the parsed content of the YAML file.
  bucket_configs = {
    for filepath in local.yaml_files :
    # Key: The filename without the extension (e.g., "my-app-logs-bucket").
    replace(basename(filepath), "/\\.(yaml|yml)$/", "") =>
    # Value: The parsed YAML content after substituting variables.
    yamldecode(
      templatefile("${var.yamls_directory}/${filepath}", var.template_values)
    )
  }
}

# 2. Create the S3 bucket resource for each configuration found.
resource "aws_s3_bucket" "this" {
  for_each = local.bucket_configs

  bucket = each.key # The bucket name comes from the filename.

  # Use try() to safely access optional attributes from the YAML file.
  # If the key doesn't exist, it uses the specified default value.
  force_destroy = try(each.value.ForceDestroy, false)
  tags          = try(each.value.Tags, {})
}

# 3. Configure versioning for each bucket based on the YAML.
resource "aws_s3_bucket_versioning" "this" {
  for_each = local.bucket_configs

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    # Defaults to "Disabled" if VersioningEnabled is not specified or is false.
    status = try(each.value.VersioningEnabled, false) ? "Enabled" : "Disabled"
  }
}

# 4. Configure server-side encryption for each bucket.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  # FIX: Corrected for_each syntax to build a valid map.
  for_each = {
    for k, v in local.bucket_configs : k => v if try(v.ServerSideEncryption, null) != null
  }

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = each.value.ServerSideEncryption.Rule.ApplyServerSideEncryptionByDefault.SseAlgorithm
      kms_master_key_id = try(each.value.ServerSideEncryption.Rule.ApplyServerSideEncryptionByDefault.KmsMasterKeyId, null)
    }
  }
}

# 5. Configure lifecycle rules for each bucket.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  # FIX: Corrected for_each syntax to build a valid map.
  for_each = {
    for k, v in local.bucket_configs : k => v if try(v.LifecycleRules, null) != null
  }

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "rule" {
    for_each = each.value.LifecycleRules

    content {
      id     = rule.value.Id
      status = rule.value.Enabled ? "Enabled" : "Disabled"

      # FIX: Replaced deprecated 'prefix' with the 'filter' block.
      filter {
        prefix = try(rule.value.Prefix, null)
      }

      dynamic "transition" {
        for_each = try(rule.value.Transitions, [])
        content {
          days          = transition.value.Days
          storage_class = transition.value.StorageClass
        }
      }

      dynamic "expiration" {
        for_each = try([rule.value.Expiration], [])
        content {
          days = expiration.value.Days
        }
      }

      # FIX: Replaced direct attribute with a dynamic block for abort_incomplete_multipart_upload.
      dynamic "abort_incomplete_multipart_upload" {
        # This loop runs once if the key exists, otherwise it does nothing.
        for_each = try(rule.value.AbortIncompleteMultipartUploadDays, null) == null ? [] : [1]
        content {
          days_after_initiation = rule.value.AbortIncompleteMultipartUploadDays
        }
      }
    }
  }
}

# 6. Configure public access block for each bucket.
resource "aws_s3_bucket_public_access_block" "this" {
  # FIX: Corrected for_each syntax to build a valid map.
  for_each = {
    for k, v in local.bucket_configs : k => v if try(v.PublicAccessBlock, null) != null
  }

  bucket = aws_s3_bucket.this[each.key].id

  block_public_acls       = each.value.PublicAccessBlock.BlockPublicAcls
  block_public_policy     = each.value.PublicAccessBlock.BlockPublicPolicy
  ignore_public_acls      = each.value.PublicAccessBlock.IgnorePublicAcls
  restrict_public_buckets = each.value.PublicAccessBlock.RestrictPublicBuckets
}