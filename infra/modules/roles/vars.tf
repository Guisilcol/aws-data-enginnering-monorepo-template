# iam_role_module/variables.tf

variable "yamls_directory" {
  type        = string
  description = "O caminho para o diretório contendo os arquivos de definição de role em formato YAML."
}

variable "template_values" {
  type        = map(any)
  description = "Um mapa de chave/valor para substituição dentro dos arquivos YAML."
  default     = {}
}