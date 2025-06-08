# outputs.tf

output "state_machine_arns" {
  description = "A map of the state machine names to their ARNs."
  value = {
    for name, sm in aws_sfn_state_machine.this : name => sm.arn
  }
}

output "state_machine_ids" {
  description = "A map of the state machine names to their IDs."
  value = {
    for name, sm in aws_sfn_state_machine.this : name => sm.id
  }
}

output "event_rule_arns" {
  description = "A map of the state machine names to their CloudWatch Event Rule ARNs."
  value = {
    for name, rule in aws_cloudwatch_event_rule.trigger : name => rule.arn
  }
}