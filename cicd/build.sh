#!/bin/bash

# Script to build AWS Lambda, Glue Job, and Step Functions applications

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
APP_DIR="app"
BUILD_DIR="build"

SHARED_SOURCE_DIR="$APP_DIR/shared"
SHARED_PKG_DEST_DIR="$BUILD_DIR/shared"

LAMBDAS_SOURCE_ROOT_DIR="$APP_DIR/01_lambda"
LAMBDAS_BUILD_OUTPUT_DIR="$BUILD_DIR/lambdas"
LAMBDAS_TEMP_PACKAGE_DIR="$BUILD_DIR/lambdas_temp_packaging"

GLUE_SOURCE_ROOT_DIR="$APP_DIR/02_glue"
GLUE_BUILD_OUTPUT_DIR="$BUILD_DIR/glue_jobs"
GLUE_WHEEL_BUILD_TEMP_ROOT_DIR="$BUILD_DIR/glue_wheel_build_temp"

# NOVO: Configuração para Step Functions
STEPFUNCTIONS_SOURCE_DIR="$APP_DIR/03_stepfunctions"
STEPFUNCTIONS_BUILD_OUTPUT_DIR="$BUILD_DIR/stepfunctions"


# --- Helper Functions ---
log_message() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S'): $1"
}

error_exit() {
    echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S'): $1" >&2
    exit 1
}

# --- 1. Prepare Build Directory ---
log_message "Creating main build directory: $BUILD_DIR"
mkdir -p "$BUILD_DIR" || error_exit "Failed to create build directory '$BUILD_DIR'."

# --- 2. Build Shared Module (for Lambdas primarily) ---
log_message "Starting build of shared module from '$SHARED_SOURCE_DIR'..."
if [ ! -f "$SHARED_SOURCE_DIR/setup.py" ]; then
    error_exit "setup.py not found in '$SHARED_SOURCE_DIR'. Cannot build shared module."
fi

mkdir -p "$SHARED_PKG_DEST_DIR" || error_exit "Failed to create directory for shared package: '$SHARED_PKG_DEST_DIR'."

current_dir=$(pwd)
cd "$SHARED_SOURCE_DIR" || error_exit "Failed to navigate to '$SHARED_SOURCE_DIR'."

log_message "Installing 'wheel' package if not already installed (needed for bdist_wheel)..."
if python -m pip install wheel --no-cache-dir --upgrade > /dev/null 2>&1; then
    log_message "'wheel' package is available."
else
    log_message "Warning: Failed to ensure 'wheel' package is installed via pip. Build might fail if not present."
fi

log_message "Running 'python setup.py bdist_wheel' for shared module..."
if python setup.py bdist_wheel > /dev/null 2>&1; then
    log_message "Shared module 'setup.py bdist_wheel' completed."
else
    error_exit "Shared module build (bdist_wheel) failed in '$SHARED_SOURCE_DIR'. Check 'python setup.py bdist_wheel' output manually."
fi

wheel_files_array=($(ls dist/*.whl 2>/dev/null))
if [ ${#wheel_files_array[@]} -eq 0 ]; then
    error_exit "No .whl file found in '$SHARED_SOURCE_DIR/dist/' after build."
elif [ ${#wheel_files_array[@]} -gt 1 ]; then
    log_message "Warning: Multiple .whl files found in '$SHARED_SOURCE_DIR/dist/'. Using the first one: ${wheel_files_array[0]}"
fi
shared_module_wheel_file="${wheel_files_array[0]}"

log_message "Copying shared module wheel '$shared_module_wheel_file' to '$current_dir/$SHARED_PKG_DEST_DIR/'..."
cp "$shared_module_wheel_file" "$current_dir/$SHARED_PKG_DEST_DIR/" || error_exit "Failed to copy shared wheel to '$current_dir/$SHARED_PKG_DEST_DIR/'."

log_message "Cleaning up temporary build files (build/, dist/, *.egg-info/) in '$SHARED_SOURCE_DIR'..."
rm -rf build dist ./*.egg-info
cd "$current_dir" || error_exit "Failed to navigate back to project root directory '$current_dir'."
log_message "Shared module built successfully. Wheel available at '$SHARED_PKG_DEST_DIR/$(basename "$shared_module_wheel_file")'."
echo

# --- 3. Package AWS Lambdas ---
log_message "Starting packaging process for AWS Lambdas from '$LAMBDAS_SOURCE_ROOT_DIR'..."
# (Seção do Lambda permanece inalterada)
# ... (código do build do Lambda omitido para brevidade) ...
if [ ! -d "$LAMBDAS_SOURCE_ROOT_DIR" ] || [ -z "$(ls -A "$LAMBDAS_SOURCE_ROOT_DIR")" ]; then
    log_message "No Lambda sources found in '$LAMBDAS_SOURCE_ROOT_DIR' or directory is empty. Skipping Lambda packaging."
else
    # O código completo do build de Lambdas iria aqui...
    log_message "Lambda packaging logic completed." # Mensagem de exemplo
fi
echo


# --- 4. Process AWS Glue Jobs (Revised Implementation) ---
log_message "Starting processing for AWS Glue Jobs from '$GLUE_SOURCE_ROOT_DIR'..."
# (Seção do Glue permanece inalterada)
# ... (código do build do Glue omitido para brevidade) ...
if [ ! -d "$GLUE_SOURCE_ROOT_DIR" ] || [ -z "$(ls -A "$GLUE_SOURCE_ROOT_DIR")" ]; then
    log_message "No Glue Job sources found in '$GLUE_SOURCE_ROOT_DIR' or directory is empty. Skipping Glue Job processing."
else
    # O código completo do build de Glue Jobs iria aqui...
    log_message "Glue Job processing logic completed." # Mensagem de exemplo
fi
echo # MODIFICADO: Adicionado um echo para consistência visual

# --- 5. Process AWS Step Functions ---
# NOVO: Seção inteira para processar os arquivos JSON das Step Functions
log_message "Starting processing for AWS Step Functions from '$STEPFUNCTIONS_SOURCE_DIR'..."

if [ ! -d "$STEPFUNCTIONS_SOURCE_DIR" ] || [ -z "$(ls -A "$STEPFUNCTIONS_SOURCE_DIR" 2>/dev/null)" ]; then
    log_message "Source directory '$STEPFUNCTIONS_SOURCE_DIR' not found or is empty. Skipping Step Functions processing."
else
    log_message "Creating Step Functions build directory: '$STEPFUNCTIONS_BUILD_OUTPUT_DIR'."
    mkdir -p "$STEPFUNCTIONS_BUILD_OUTPUT_DIR" || error_exit "Failed to create directory '$STEPFUNCTIONS_BUILD_OUTPUT_DIR'."

    # Verifica se existem arquivos .json antes de tentar copiar
    if ls "$STEPFUNCTIONS_SOURCE_DIR"/*.json &> /dev/null; then
        log_message "Copying JSON files to '$STEPFUNCTIONS_BUILD_OUTPUT_DIR'..."
        cp "$STEPFUNCTIONS_SOURCE_DIR"/*.json "$STEPFUNCTIONS_BUILD_OUTPUT_DIR/" || error_exit "Failed to copy Step Function JSON files."
        log_message "Successfully copied JSON files to '$STEPFUNCTIONS_BUILD_OUTPUT_DIR'."
    else
        log_message "No .json files found in '$STEPFUNCTIONS_SOURCE_DIR'. Nothing to copy."
    fi
fi


# --- Script finalizado ---
log_message "Build script finished successfully! 🎉"
exit 0