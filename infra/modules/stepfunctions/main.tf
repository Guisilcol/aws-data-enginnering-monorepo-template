# Find all YAML files in the specified directory and parse their content.
locals {
  definition_files = fileset(var.definitions_directory, "**/*.yaml")

  step_functions = {
    for file in local.definition_files :
    trimsuffix(file, ".yaml") => yamldecode(file("${var.definitions_directory}/${file}"))
  }
}

# Create the AWS Step Function state machine for each definition found.
resource "aws_sfn_state_machine" "this" {
  for_each = local.step_functions

  name       = each.value.name
  role_arn   = var.role_arn
  definition = file("${abspath(var.definitions_directory)}/${each.value.definition_path}")

  tags = {
    Name = each.value.name
  }
}

# Create a CloudWatch Event Rule for Step Functions triggered by a CRON schedule.
resource "aws_cloudwatch_event_rule" "scheduled" {
  for_each = {
    for key, value in local.step_functions : key => value
    if lookup(value, "schedule_expression", null) != null
  }

  name                = "${each.value.name}-schedule-rule"
  schedule_expression = each.value.schedule_expression
}

# Create a target to link the scheduled rule to the corresponding Step Function.
resource "aws_cloudwatch_event_target" "scheduled" {
  for_each = aws_cloudwatch_event_rule.scheduled

  rule = each.value.name
  arn  = aws_sfn_state_machine.this[each.key].arn
}

# Create a CloudWatch Event Rule for Step Functions triggered by an event pattern.
resource "aws_cloudwatch_event_rule" "event_driven" {
  for_each = {
    for key, value in local.step_functions : key => value
    if lookup(value, "event_pattern", null) != null
  }

  name          = "${each.value.name}-event-rule"
  event_pattern = each.value.event_pattern
}

# Create a target to link the event-driven rule to the corresponding Step Function.
resource "aws_cloudwatch_event_target" "event_driven" {
  for_each = aws_cloudwatch_event_rule.event_driven

  rule = each.value.name
  arn  = aws_sfn_state_machine.this[each.key].arn
}