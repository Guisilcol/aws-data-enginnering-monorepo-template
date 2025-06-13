#!/bin/bash

# Script para preparar as definições de AWS Step Functions para o deploy.
# Ele copia os arquivos de definição .json para o diretório de distribuição.

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
# Diretório onde as definições das Step Functions estão localizadas.
SFN_SRC_DIR="app/03_stepfunctions"

# Diretório de distribuição onde as definições prontas serão colocadas.
SFN_DIST_DIR="build/stepfunctions"


# --- Script Principal ---

log_info "Iniciando a preparação das definições das Step Functions..."

# 1. Validação
if [ ! -d "$SFN_SRC_DIR" ]; then
  log_error "O diretório de origem das Step Functions '${SFN_SRC_DIR}' não foi encontrado."
fi

# 2. Limpar builds anteriores e criar diretório de destino
log_info "Limpando o diretório de destino '${SFN_DIST_DIR}'..."
rm -rf "$SFN_DIST_DIR"

log_info "Criando o diretório de destino '${SFN_DIST_DIR}'..."
mkdir -p "$SFN_DIST_DIR"

# 3. Copiar os arquivos de definição
log_info "Copiando os arquivos de '${SFN_SRC_DIR}' para '${SFN_DIST_DIR}'..."

# Copia todos os arquivos do diretório de origem para o de destino.
if ! rsync -av "${SFN_SRC_DIR}/" "${SFN_DIST_DIR}/"; then
    log_error "Falha ao copiar os arquivos de definição das Step Functions."
fi

# Verificação final para garantir que os arquivos foram copiados.
file_count=$(ls -1q "${SFN_DIST_DIR}" | wc -l)
if [ "$file_count" -eq 0 ]; then
    log_info "Atenção: Nenhuma definição foi encontrada em '${SFN_SRC_DIR}' para copiar."
else
    log_info "${file_count} arquivo(s) de definição foram preparados com sucesso."
fi

log_info "Preparação das Step Functions concluída!"
log_info "Definições prontas para deploy em: ${SFN_DIST_DIR}"

exit 0