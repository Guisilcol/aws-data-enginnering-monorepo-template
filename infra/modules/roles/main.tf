# iam_role_module/main.tf

locals {
  # 1. Encontra todos os arquivos .yaml ou .yml no diretório especificado.
  yaml_files = fileset(var.yamls_directory, "**/*.{yaml,yml}")

  # 2. (ETAPA INTERMEDIÁRIA) Lê e processa cada arquivo YAML aplicando as variáveis do template.
  #    O resultado é uma lista de objetos, cada um representando um arquivo YAML.
  processed_yamls = [
    for file_path in local.yaml_files :
    yamldecode(
      templatefile("${var.yamls_directory}/${file_path}", var.template_variables)
    )
  ]

  # 3. (ETAPA FINAL) Cria o mapa principal de dados das roles.
  #    A chave do mapa agora é o valor do campo "Name" de dentro do próprio YAML.
  #    Isso nos permite usar o nome definido no arquivo para criar e referenciar a role.
  roles_data = {
    for config in local.processed_yamls : config.Name => config
  }

  # 4. Cria uma lista "achatada" (flatten) de todas as políticas inline de todas as roles.
  #    Esta lógica permanece a mesma, mas agora consome `local.roles_data` que usa a nova chave.
  inline_policies = flatten([
    for role_name, role_config in local.roles_data : [
      for policy in lookup(role_config, "InlinePolicies", []) : {
        role_name         = role_name
        policy_name       = policy.Name
        policy_document   = policy.PolicyDocument
      }
    ]
  ])
}

# Cria uma IAM Role para cada configuração de role encontrada.
resource "aws_iam_role" "from_yaml" {
  for_each = local.roles_data

  # `each.key` agora contém o valor do campo "Name" do YAML.
  name               = each.key
  description        = lookup(each.value, "Description", "Role criada pelo módulo Terraform.")
  assume_role_policy = jsonencode(each.value.AssumeRolePolicy)
  tags               = lookup(each.value, "Tags", {})
}

# Cria as políticas inline para cada role correspondente.
resource "aws_iam_role_policy" "inline" {
  for_each = { for policy in local.inline_policies : "${policy.role_name}.${policy.policy_name}" => policy }

  name   = each.value.policy_name
  # A referência `aws_iam_role.from_yaml[each.value.role_name]` continua funcionando
  # porque `each.value.role_name` agora corresponde à chave correta (`Name` do YAML).
  role   = aws_iam_role.from_yaml[each.value.role_name].id
  policy = jsonencode(each.value.policy_document)
}