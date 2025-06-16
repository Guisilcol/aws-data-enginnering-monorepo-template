output "step_function_arns" {
  description = "A map of the ARNs of the created Step Functions."
  value       = { for key, sfn in aws_sfn_state_machine.this : key => sfn.arn }
}

output "step_function_ids" {
  description = "A map of the IDs of the created Step Functions."
  value       = { for key, sfn in aws_sfn_state_machine.this : key => sfn.id }
}