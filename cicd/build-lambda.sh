#!/bin/bash

# Script para construir os pacotes de deploy para as funções Lambda.
# Ele pode construir todas as Lambdas em src/lambdas ou uma Lambda específica.

# Sai imediatamente se um comando falhar.
set -e

# --- Funções de Ajuda ---
function log_info() {
  echo "[INFO] $1"
}

function log_error() {
  echo "[ERROR] $1" >&2
  exit 1
}

# --- Configuração ---
# Diretório raiz onde os códigos-fonte das Lambdas estão localizados.
LAMBDAS_SRC_DIR="app/01_lambda"

# Diretório de distribuição onde os pacotes .zip serão salvos.
DIST_DIR="build/lambda"


# --- Função de Build Principal ---

# Função para construir uma única função Lambda.
# Argumento 1: O nome da função Lambda (que deve corresponder ao nome do diretório).
build_lambda() {
  local lambda_name=$1
  local lambda_src_path="${LAMBDAS_SRC_DIR}/${lambda_name}"
  local requirements_file="${lambda_src_path}/requirements.txt"
  local zip_file_path="${DIST_DIR}/${lambda_name}.zip"
  
  # Diretório de build temporário para esta Lambda específica.
  local build_dir_temp="${DIST_DIR}/build_temp_${lambda_name}"

  log_info "--- Iniciando build para a Lambda: ${lambda_name} ---"

  # 1. Validação
  if [ ! -d "$lambda_src_path" ]; then
    log_error "O diretório da Lambda '${lambda_src_path}' não foi encontrado."
  fi

  # 2. Limpeza
  rm -rf "$build_dir_temp" "$zip_file_path"
  mkdir -p "$build_dir_temp"

  # 3. Copiar código-fonte da Lambda
  log_info "Copiando código-fonte de '${lambda_src_path}'..."
  rsync -av --exclude 'requirements.txt' "${lambda_src_path}/" "${build_dir_temp}/"

  # 4. Instalar dependências específicas da Lambda
  if [ -f "$requirements_file" ]; then
    log_info "Instalando dependências de '${requirements_file}'..."
    if ! pip install -r "$requirements_file" -t "$build_dir_temp"; then
      log_error "Falha ao instalar dependências para a Lambda '${lambda_name}'."
    fi
  else
    log_info "Nenhum 'requirements.txt' específico encontrado para '${lambda_name}'."
  fi

  # 5. Criar o arquivo .zip
  log_info "Criando o pacote de deploy em '${zip_file_path}'..."
  local current_dir=$(pwd)
  cd "$build_dir_temp"
  if ! zip -r "${current_dir}/${zip_file_path}" .; then
    cd "$current_dir"
    log_error "Falha ao criar o arquivo zip para a Lambda '${lambda_name}'."
  fi
  cd "$current_dir"

  # 6. Limpar diretório de build temporário
  rm -rf "$build_dir_temp"

  log_info "--- Build da Lambda '${lambda_name}' concluído com sucesso! ---"
}


# --- Script Principal ---

# Garante que o diretório de distribuição exista.
mkdir -p "$DIST_DIR"

# Verifica se um nome de Lambda específico foi passado como argumento.
if [ -n "$1" ]; then
  # Constrói apenas a Lambda especificada.
  TARGET_LAMBDA=$1
  log_info "Modo de build: Apenas a Lambda '${TARGET_LAMBDA}' será construída."
  build_lambda "$TARGET_LAMBDA"
else
  # Constrói todas as Lambdas encontradas em LAMBDAS_SRC_DIR.
  log_info "Modo de build: Todas as Lambdas em '${LAMBDAS_SRC_DIR}' serão construídas."
  
  # Valida se o diretório principal das Lambdas existe.
  if [ ! -d "$LAMBDAS_SRC_DIR" ]; then
      log_error "O diretório principal das Lambdas '${LAMBDAS_SRC_DIR}' não foi encontrado."
  fi

  # Itera sobre cada subdiretório em LAMBDAS_SRC_DIR.
  for lambda_dir in "${LAMBDAS_SRC_DIR}"/*/; do
    # Extrai o nome da Lambda a partir do caminho do diretório.
    lambda_name=$(basename "$lambda_dir")
    if [ -n "$lambda_name" ]; then
      build_lambda "$lambda_name"
    fi
  done
fi

log_info "Todos os builds de Lambda solicitados foram concluídos."

exit 0