#!/bin/bash

# Script to build AWS Lambda and Glue Job applications

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
APP_DIR="app"
BUILD_DIR="build"

SHARED_SOURCE_DIR="$APP_DIR/shared"
# Directory where the built shared module (.whl file) will be stored
SHARED_PKG_DEST_DIR="$BUILD_DIR/shared" # Corrected typo here

LAMBDAS_SOURCE_ROOT_DIR="$APP_DIR/01_lambda"
LAMBDAS_BUILD_OUTPUT_DIR="$BUILD_DIR/lambdas"
# Temporary directory for packaging individual lambdas
LAMBDAS_TEMP_PACKAGE_DIR="$BUILD_DIR/lambdas_temp_packaging"

GLUE_SOURCE_ROOT_DIR="$APP_DIR/02_glue"
# Directory where processed Glue jobs will be stored
GLUE_BUILD_OUTPUT_DIR="$BUILD_DIR/glue_jobs"
# Temporary directory for building custom wheels for Glue jobs
GLUE_WHEEL_BUILD_TEMP_ROOT_DIR="$BUILD_DIR/glue_wheel_build_temp"


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

# Create destination for the shared package (.whl)
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
mkdir -p "$LAMBDAS_BUILD_OUTPUT_DIR" || error_exit "Failed to create Lambdas output directory '$LAMBDAS_BUILD_OUTPUT_DIR'."
mkdir -p "$LAMBDAS_TEMP_PACKAGE_DIR" || error_exit "Failed to create Lambdas temporary packaging directory '$LAMBDAS_TEMP_PACKAGE_DIR'."

if [ ! -d "$LAMBDAS_SOURCE_ROOT_DIR" ] || [ -z "$(ls -A "$LAMBDAS_SOURCE_ROOT_DIR")" ]; then
    log_message "No Lambda sources found in '$LAMBDAS_SOURCE_ROOT_DIR' or directory is empty. Skipping Lambda packaging."
else
    shared_wheel_path_array=($(ls "$SHARED_PKG_DEST_DIR"/*.whl 2>/dev/null))
    shared_module_wheel_to_install=""
    if [ ${#shared_wheel_path_array[@]} -gt 0 ]; then
        shared_module_wheel_to_install="${shared_wheel_path_array[0]}"
    else
        log_message "Warning: No shared module .whl file found in '$SHARED_PKG_DEST_DIR'. Lambdas will be packaged without it if it was expected."
    fi

    for lambda_source_dir_path in "$LAMBDAS_SOURCE_ROOT_DIR"/*/; do
        if [ -d "$lambda_source_dir_path" ]; then # Ensures it's a directory
            lambda_name=$(basename "$lambda_source_dir_path")
            log_message "Packaging Lambda: '$lambda_name'..."
            current_lambda_work_dir="$LAMBDAS_TEMP_PACKAGE_DIR/$lambda_name"
            rm -rf "$current_lambda_work_dir" # Clean before use
            mkdir -p "$current_lambda_work_dir" || error_exit "Failed to create temporary work directory for Lambda '$lambda_name'."

            log_message "Copying all Lambda files (including diverse files/folders) for '$lambda_name' from '$lambda_source_dir_path' to '$current_lambda_work_dir'..."
            # Use a subshell to enable dotglob locally for the copy command
            (
                shopt -s dotglob nullglob # Enable dotglob to include hidden files/folders
                # lambda_source_dir_path ends with '/', so * correctly expands to its contents
                cp -R ${lambda_source_dir_path}* "$current_lambda_work_dir/" || error_exit "Failed to copy files for Lambda '$lambda_name'."
                shopt -u dotglob nullglob # Disable dotglob
            )

            if [ -n "$shared_module_wheel_to_install" ] && [ -f "$shared_module_wheel_to_install" ]; then
                log_message "Installing shared module '$shared_module_wheel_to_install' into '$current_lambda_work_dir' for Lambda '$lambda_name'..."
                if python -m pip install "$shared_module_wheel_to_install" -t "$current_lambda_work_dir" --no-cache-dir --upgrade > /dev/null; then
                    log_message "Shared module installed successfully for Lambda '$lambda_name'."
                else
                    error_exit "Failed to install shared module for Lambda '$lambda_name'."
                fi
            else
                log_message "Shared module wheel not found or not specified; skipping installation for Lambda '$lambda_name'."
            fi

            lambda_requirements_file="$current_lambda_work_dir/requirements.txt" # Path is now within the work dir
            if [ -f "$lambda_requirements_file" ]; then
                log_message "Installing dependencies from '$lambda_requirements_file' into '$current_lambda_work_dir' for Lambda '$lambda_name'..."
                if python -m pip install -r "$lambda_requirements_file" -t "$current_lambda_work_dir" --no-cache-dir --upgrade > /dev/null; then
                    log_message "Dependencies installed successfully for Lambda '$lambda_name'."
                else
                    error_exit "Failed to install requirements for Lambda '$lambda_name' from '$lambda_requirements_file'."
                fi
            else
                # Check original location if not found in work_dir (though cp should have brought it)
                original_req_file="${lambda_source_dir_path}requirements.txt"
                if [ ! -f "$original_req_file" ]; then
                     log_message "No 'requirements.txt' found for Lambda '$lambda_name'. Skipping dependency installation."
                else
                    # This case should ideally not be hit if the copy worked and requirements.txt was present.
                    log_message "Warning: requirements.txt not found in '$current_lambda_work_dir' but present in source. Check copy step. Skipping for now."
                fi
            fi

            log_message "Creating zip package for Lambda '$lambda_name'..."
            lambda_zip_file_path="$LAMBDAS_BUILD_OUTPUT_DIR/$lambda_name.zip"
            (
                cd "$current_lambda_work_dir" || exit 1
                # Using . to zip all contents of current_lambda_work_dir, including hidden files at root
                if zip -qr "$current_dir/$lambda_zip_file_path" . ; then
                    log_message "Lambda '$lambda_name' packaged successfully: '$lambda_zip_file_path'"
                else
                    error_exit "Failed to create zip package for Lambda '$lambda_name'."
                fi
            ) || error_exit "Subshell for zipping Lambda '$lambda_name' failed."
        fi
    done
    log_message "Cleaning up temporary Lambda packaging directory: '$LAMBDAS_TEMP_PACKAGE_DIR'..."
    rm -rf "$LAMBDAS_TEMP_PACKAGE_DIR"
fi
echo

# --- 4. Process AWS Glue Jobs (Revised Implementation) ---
log_message "Starting processing for AWS Glue Jobs from '$GLUE_SOURCE_ROOT_DIR'..."
mkdir -p "$GLUE_BUILD_OUTPUT_DIR" || error_exit "Failed to create Glue Jobs output directory '$GLUE_BUILD_OUTPUT_DIR'."
mkdir -p "$GLUE_WHEEL_BUILD_TEMP_ROOT_DIR" || error_exit "Failed to create Glue wheel build temp root directory '$GLUE_WHEEL_BUILD_TEMP_ROOT_DIR'."

if [ ! -d "$GLUE_SOURCE_ROOT_DIR" ] || [ -z "$(ls -A "$GLUE_SOURCE_ROOT_DIR")" ]; then
    log_message "No Glue Job sources found in '$GLUE_SOURCE_ROOT_DIR' or directory is empty. Skipping Glue Job processing."
else
    shared_code_package_source_dir="$SHARED_SOURCE_DIR/shared" # Path to app/shared/shared/

    for glue_job_source_dir_path in "$GLUE_SOURCE_ROOT_DIR"/*/; do
        if [ -d "$glue_job_source_dir_path" ]; then # Ensures it's a directory
            glue_job_name=$(basename "$glue_job_source_dir_path")
            log_message "Processing Glue Job: '$glue_job_name'..."

            current_glue_job_final_target_dir="$GLUE_BUILD_OUTPUT_DIR/$glue_job_name"
            rm -rf "$current_glue_job_final_target_dir" 
            mkdir -p "$current_glue_job_final_target_dir" || error_exit "Failed to create final target directory for Glue Job '$glue_job_name'."

            glue_main_py_source_path="${glue_job_source_dir_path}main.py" # Assuming dir path ends with /
            if [ ! -f "$glue_main_py_source_path" ]; then
                log_message "Warning: main.py not found for Glue job '$glue_job_name' in '$glue_job_source_dir_path'. Skipping this job."
                continue 
            fi
            log_message "Copying '$glue_main_py_source_path' to '$current_glue_job_final_target_dir/'..."
            cp "$glue_main_py_source_path" "$current_glue_job_final_target_dir/" || error_exit "Failed to copy main.py for '$glue_job_name'."

            log_message "Copying other assets and local modules for '$glue_job_name' from '$glue_job_source_dir_path' to '$current_glue_job_final_target_dir'..."
            (
                shopt -s dotglob nullglob # Enable dotglob for this subshell command
                # glue_job_source_dir_path ends with '/', so * correctly expands to its contents
                for item in "${glue_job_source_dir_path}"*; do
                    item_name=$(basename "$item")
                    if [[ "$item_name" != "main.py" && "$item_name" != "requirements.txt" ]]; then
                        cp -R "$item" "$current_glue_job_final_target_dir/" || error_exit "Failed to copy additional item '$item' for '$glue_job_name'."
                    fi
                done
                shopt -u dotglob nullglob # Disable dotglob
            )

            current_job_wheel_source_staging_dir="$GLUE_WHEEL_BUILD_TEMP_ROOT_DIR/$glue_job_name"
            rm -rf "$current_job_wheel_source_staging_dir" 
            mkdir -p "$current_job_wheel_source_staging_dir" || error_exit "Failed to create wheel source staging dir for '$glue_job_name'."

            if [ -d "$shared_code_package_source_dir" ]; then
                log_message "Copying shared code from '$shared_code_package_source_dir' to '$current_job_wheel_source_staging_dir/shared'..."
                cp -R "$shared_code_package_source_dir" "$current_job_wheel_source_staging_dir/shared" || error_exit "Failed to copy shared code for '$glue_job_name'."
            else
                log_message "Shared code package directory '$shared_code_package_source_dir' not found. Glue job wheel for '$glue_job_name' will not include 'shared' code from there."
            fi
            
            # REMOVED: Section that copied local job modules into wheel source. They are now copied alongside main.py.

            glue_job_requirements_file_path="${glue_job_source_dir_path}requirements.txt" # Assuming dir path ends with /
            if [ -f "$glue_job_requirements_file_path" ]; then
                log_message "Installing dependencies from '$glue_job_requirements_file_path' into '$current_job_wheel_source_staging_dir' for Glue Job '$glue_job_name' wheel..."
                if python -m pip install -r "$glue_job_requirements_file_path" -t "$current_job_wheel_source_staging_dir" --no-cache-dir --upgrade > /dev/null; then
                    log_message "Dependencies from requirements.txt installed into wheel source for '$glue_job_name'."
                else
                    error_exit "Failed to install requirements into wheel source for '$glue_job_name' from '$glue_job_requirements_file_path'."
                fi
            else
                log_message "No 'requirements.txt' found for Glue Job '$glue_job_name' at '$glue_job_requirements_file_path'. Wheel will not include additional pip dependencies."
            fi

            safe_glue_job_name=$(echo "$glue_job_name" | tr '-' '_') # Sanitize name for Python package
            glue_job_wheel_setup_py_content=$(cat <<EOF
from setuptools import setup, find_packages

setup(
    name="${safe_glue_job_name}_job_dependencies_wheel",
    version="1.0.0",
    packages=find_packages(), # Will find 'shared' and packages from requirements.txt
    description="Custom wheel for Glue job ${glue_job_name}, including shared code and PyPI dependencies."
)
EOF
)
            echo "$glue_job_wheel_setup_py_content" > "$current_job_wheel_source_staging_dir/setup.py"
            log_message "Generated setup.py for '$glue_job_name' wheel in '$current_job_wheel_source_staging_dir'."

            log_message "Building wheel for Glue Job '$glue_job_name' from '$current_job_wheel_source_staging_dir'..."
            (
                cd "$current_job_wheel_source_staging_dir" || exit 1 
                if python setup.py bdist_wheel > /dev/null 2>&1; then 
                    log_message "Wheel built successfully for '$glue_job_name'."
                else
                    error_exit "Failed to build wheel for Glue Job '$glue_job_name'. Check 'python setup.py bdist_wheel' output in '$current_job_wheel_source_staging_dir'."
                fi

                built_wheel_files_array=($(ls dist/*.whl 2>/dev/null))
                if [ ${#built_wheel_files_array[@]} -eq 0 ]; then
                    error_exit "No .whl file found in '$current_job_wheel_source_staging_dir/dist/' after build for '$glue_job_name'."
                elif [ ${#built_wheel_files_array[@]} -gt 1 ]; then
                    log_message "Warning: Multiple .whl files found in '$current_job_wheel_source_staging_dir/dist/'. Using the first one: ${built_wheel_files_array[0]}"
                fi
                cp "${built_wheel_files_array[0]}" "$current_dir/$current_glue_job_final_target_dir/" || error_exit "Failed to copy wheel for '$glue_job_name' to '$current_glue_job_final_target_dir/'."
                log_message "Custom wheel for Glue Job '$glue_job_name' copied to '$current_glue_job_final_target_dir/$(basename "${built_wheel_files_array[0]}")'."
            ) || error_exit "Subshell for building Glue wheel for '$glue_job_name' failed."
            log_message "Glue Job '$glue_job_name' processed. Output: '$current_glue_job_final_target_dir/'"
        fi
    done

    log_message "Cleaning up global Glue wheel temporary build source directory: '$GLUE_WHEEL_BUILD_TEMP_ROOT_DIR'..."
    rm -rf "$GLUE_WHEEL_BUILD_TEMP_ROOT_DIR"
fi

log_message "Build script finished successfully! 🎉"
exit 0