#!/bin/bash

# Script para construir o pacote de código compartilhado.
# Gera dois artefatos:
# 1. Um arquivo .zip para uso como Lambda Layer ou em jobs do Glue.
# 2. Um arquivo .whl (wheel) para instalação via pip.

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
# Diretório onde o código-fonte compartilhado está localizado.
SHARED_SRC_DIR="app/shared"

# Arquivo que lista as dependências do Python.
REQUIREMENTS_FILE="${SHARED_SRC_DIR}/requirements.txt"

# Arquivo de setup para o pacote wheel.
SETUP_FILE="${SHARED_SRC_DIR}/setup.py"

# Diretório de distribuição onde os artefatos finais serão colocados.
DIST_DIR="build/shared"

# Diretório de build temporário para o ZIP.
BUILD_DIR_ZIP="${DIST_DIR}/python"

# Nome do arquivo zip de saída.
ZIP_FILE_NAME="shared_layer.zip"
ZIP_FILE_PATH="${DIST_DIR}/${ZIP_FILE_NAME}"


# --- Script Principal ---

log_info "Iniciando o build dos pacotes de código compartilhado..."

# 1. Validações
if [ ! -d "$SHARED_SRC_DIR" ]; then
  log_error "O diretório de código-fonte '${SHARED_SRC_DIR}' não foi encontrado."
fi
if [ ! -f "$SETUP_FILE" ]; then
  log_error "Arquivo '${SETUP_FILE}' não encontrado. Ele é necessário para criar o pacote wheel."
fi

# 2. Limpar builds anteriores e criar diretório de distribuição
log_info "Limpando artefatos de builds anteriores em '${DIST_DIR}'..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# -----------------------------------------------------------
# ETAPA A: Construir o arquivo Wheel (.whl)
# -----------------------------------------------------------
log_info "--- Construindo o arquivo Wheel (.whl) ---"

# Guarda o diretório atual para poder voltar
CURRENT_DIR=$(pwd)

# Entra no diretório do código-fonte para executar o build
cd "$SHARED_SRC_DIR"

# Instala "wheel" 
pip install wheel build

log_info "Executando o comando de build do pacote..."
# Usamos 'python -m build' que é a abordagem moderna e recomendada.
if ! python -m build; then
    cd "$CURRENT_DIR"
    log_error "Falha ao construir o pacote wheel. Verifique seu 'setup.py' e se os pacotes 'build' e 'wheel' estão instalados."
fi

# Volta para o diretório original
cd "$CURRENT_DIR"

# Move o arquivo .whl gerado para o diretório de distribuição final
log_info "Movendo o arquivo .whl para '${DIST_DIR}'..."
mv "${SHARED_SRC_DIR}/dist/"*.whl "${DIST_DIR}/"

# Informa o nome do arquivo gerado
WHEEL_FILE_NAME=$(basename "${DIST_DIR}"/*.whl)
log_info "Arquivo wheel '${WHEEL_FILE_NAME}' criado com sucesso! ✅"

# Limpa os diretórios temporários criados pelo processo de build do wheel
rm -rf "${SHARED_SRC_DIR}/dist" "${SHARED_SRC_DIR}/build" "${SHARED_SRC_DIR}"/*.egg-info


# -----------------------------------------------------------
# ETAPA B: Construir o arquivo Zip para Lambda Layer
# -----------------------------------------------------------
log_info "--- Construindo o arquivo Zip para Lambda Layer ---"

# Cria o diretório de build para o zip
log_info "Criando diretório de build em '${BUILD_DIR_ZIP}'..."
mkdir -p "$BUILD_DIR_ZIP"

# Instala dependências do pip no diretório do zip
if [ -f "$REQUIREMENTS_FILE" ]; then
  log_info "Instalando dependências de '${REQUIREMENTS_FILE}' para o zip..."
  if ! pip install -r "$REQUIREMENTS_FILE" -t "$BUILD_DIR_ZIP"; then
    log_error "Falha ao instalar as dependências do pip para o zip."
  fi
else
  log_info "Nenhum 'requirements.txt' encontrado. Pulando a instalação de dependências para o zip."
fi

# Copia o código-fonte compartilhado para o diretório do zip
log_info "Copiando o código-fonte para o diretório do zip..."
if ! rsync -av --exclude 'requirements.txt' --exclude 'setup.py' "${SHARED_SRC_DIR}/" "${BUILD_DIR_ZIP}/"; then
    log_error "Falha ao copiar o código-fonte compartilhado para o zip."
fi

# Cria o arquivo zip
log_info "Criando o arquivo zip '${ZIP_FILE_PATH}'..."
cd "$BUILD_DIR_ZIP"
if ! zip -r "${CURRENT_DIR}/${ZIP_FILE_PATH}" .; then
    cd "$CURRENT_DIR"
    log_error "Falha ao criar o arquivo zip."
fi
cd "$CURRENT_DIR"

log_info "Arquivo zip '${ZIP_FILE_NAME}' criado com sucesso! ✅"


# --- Conclusão ---
log_info "Build de todos os artefatos concluído."
log_info "Artefatos gerados em: ${DIST_DIR}/"
log_info "  - Wheel: ${WHEEL_FILE_NAME}"
log_info "  - Zip Layer: ${ZIP_FILE_NAME}"

exit 0