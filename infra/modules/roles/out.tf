# iam_role_module/outputs.tf

output "created_roles_arn" {
  description = "Mapa com os ARNs das roles criadas. A chave é o nome da role."
  value       = { for name, role in aws_iam_role.from_yaml : name => role.arn }
}

output "created_roles_name" {
  description = "Mapa com os nomes das roles criadas. A chave é o nome da role."
  value       = { for name, role in aws_iam_role.from_yaml : name => role.name }
}