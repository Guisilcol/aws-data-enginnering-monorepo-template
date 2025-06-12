#!/bin/bash

# Script para preparar os scripts de jobs do AWS Glue para o deploy.
# Ele copia os scripts .py ou .scala para o diretório de distribuição.

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
# Diretório onde os scripts dos jobs do Glue estão localizados.
GLUE_SRC_DIR="app/02_glue"

# Diretório de distribuição onde os scripts prontos serão colocados.
GLUE_DIST_DIR="build/glue"


# --- Script Principal ---

log_info "Iniciando a preparação dos scripts dos jobs do Glue..."

# 1. Validação
if [ ! -d "$GLUE_SRC_DIR" ]; then
  log_error "O diretório de origem dos jobs do Glue '${GLUE_SRC_DIR}' não foi encontrado."
fi

# 2. Limpar builds anteriores e criar diretório de destino
log_info "Limpando o diretório de destino '${GLUE_DIST_DIR}'..."
rm -rf "$GLUE_DIST_DIR"

log_info "Criando o diretório de destino '${GLUE_DIST_DIR}'..."
mkdir -p "$GLUE_DIST_DIR"

# 3. Copiar os scripts dos jobs
log_info "Copiando os scripts de '${GLUE_SRC_DIR}' para '${GLUE_DIST_DIR}'..."

# Copia todos os arquivos do diretório de origem para o de destino.
# Usamos 'rsync' por ser robusto.
if ! rsync -av "${GLUE_SRC_DIR}/" "${GLUE_DIST_DIR}/"; then
    log_error "Falha ao copiar os scripts dos jobs do Glue."
fi

# Verificação final para garantir que os arquivos foram copiados.
file_count=$(ls -1q "${GLUE_DIST_DIR}" | wc -l)
if [ "$file_count" -eq 0 ]; then
    log_info "Atenção: Nenhum script foi encontrado em '${GLUE_SRC_DIR}' para copiar."
else
    log_info "${file_count} script(s) foram preparados com sucesso."
fi


log_info "Preparação dos scripts do Glue concluída! ✅"
log_info "Scripts prontos para deploy em: ${GLUE_DIST_DIR}"

exit 0