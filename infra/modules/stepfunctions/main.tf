# main.tf

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  yaml_files = fileset(var.yamls_directory, "**/*.{yaml,yml}")

  # Process each YAML file with a two-step template approach.
  state_machines = {
    for file_path in local.yaml_files :
    trimsuffix(basename(file_path), ".yaml") => {
      # --- UPDATED LOGIC ---
      # 1. The YAML file itself is rendered using the module's input variables.
      # 2. The resulting YAML string is then decoded.
      config = yamldecode(templatefile("${var.yamls_directory}/${file_path}", var.template_variables))
      
      source_path = file_path
    }
  }
}

resource "aws_sfn_state_machine" "this" {
  for_each = local.state_machines

  name     = each.key
  role_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${each.value.config.RoleName}"

  # --- UPDATED LOGIC ---
  # The definition now uses the 'DefinitionVariables' map from the rendered YAML.
  definition = templatefile("${var.yamls_directory}/${each.value.config.DefinitionPath}", merge(
      # Use variables from the new `DefinitionVariables` block in the YAML.
      # The try() function provides an empty map if the block is omitted, preventing errors.
      try(each.value.config.DefinitionVariables, {}),
      
      # We still automatically inject the Comment for convenience.
      {
        Comment = try(each.value.config.Comment, "State machine for ${each.key}")
      }
    )
  )

  logging_configuration {
    log_destination        = try(each.value.config.LoggingConfiguration.Level, "OFF") != "OFF" ? aws_cloudwatch_log_group.this[each.key].arn : null
    include_execution_data = try(each.value.config.LoggingConfiguration.IncludeExecutionData, false)
    level                  = try(each.value.config.LoggingConfiguration.Level, "OFF")
  }

  tracing_configuration {
    enabled = try(each.value.config.TracingConfiguration.Enabled, false)
  }

  # The `try` function here is robust enough to handle templated tags.
  tags = try(each.value.config.Tags, {})

  depends_on = [aws_cloudwatch_log_group.this]
}

# The rest of the file (log group, event rule, event target) remains unchanged.
# ... (aws_cloudwatch_log_group, aws_cloudwatch_event_rule, aws_cloudwatch_event_target) ...