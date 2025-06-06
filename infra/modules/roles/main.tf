# iam_role_module/main.tf

locals {
  # 1. Encontra todos os arquivos .yaml ou .yml no diretório especificado.
  yaml_files = fileset(var.yamls_directory, "**/*.{yaml,yml}")

  # 2. Cria um mapa onde a chave é o nome da role (derivado do nome do arquivo)
  #    e o valor é o conteúdo do YAML decodificado após a substituição das variáveis.
  #    A função `trimsuffix` remove a extensão `.yaml` para obter o nome limpo da role.
  roles_data = {
    for file_path in local.yaml_files :
    trimsuffix(basename(file_path), ".yaml") => yamldecode(
      templatefile("${var.yamls_directory}/${file_path}", var.template_variables)
    )
  }

  # 3. Cria uma lista flatten de todas as políticas inline.
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

# Cria uma IAM Role para cada arquivo YAML encontrado.
resource "aws_iam_role" "from_yaml" {
  for_each = local.roles_data

  # `each.key` agora contém o nome do arquivo, que será o nome da role.
  name               = each.key
  description        = lookup(each.value, "Description", "Role criada pelo módulo Terraform.")
  assume_role_policy = jsonencode(each.value.AssumeRolePolicy)
  tags               = lookup(each.value, "Tags", {})
}

# Cria as políticas inline para cada role correspondente.
resource "aws_iam_role_policy" "inline" {
  for_each = { for policy in local.inline_policies : "${policy.role_name}.${policy.policy_name}" => policy }

  name   = each.value.policy_name
  # A referência continua funcionando, pois `each.value.role_name` corresponde ao nome do arquivo.
  role   = aws_iam_role.from_yaml[each.value.role_name].id
  policy = jsonencode(each.value.policy_document)
}