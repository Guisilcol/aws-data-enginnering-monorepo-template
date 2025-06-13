#!/bin/bash

# Script to deploy infrastructure using Terraform from the ./infra subdirectory

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
TERRAFORM_CMD="terraform"
ALLOWED_ENVIRONMENTS=("dev" "prd")
INFRA_DIR="infra" # Define the infrastructure directory

# --- Helper Functions ---
function usage() {
  echo "Usage: $0 <environment> <aws_profile>"
  echo "  <environment>: The deployment environment. Must be one of: ${ALLOWED_ENVIRONMENTS[*]}"
  echo "  <aws_profile>: The AWS CLI profile to use for authentication."
  echo ""
  echo "Note: This script expects Terraform files to be in a subdirectory named './${INFRA_DIR}'"
  echo ""
  echo "Example: $0 dev my-dev-profile"
  exit 1
}

function log_info() {
  echo "[INFO] $1"
}

function log_error() {
  echo "[ERROR] $1" >&2
  exit 1
}

# --- Main Script ---

# 1. Validate script arguments
if [ "$#" -ne 2 ]; then
  log_error "Incorrect number of arguments provided."
  usage
fi

TARGET_ENV="$1"
AWS_PROFILE_NAME="$2"

# 2. Validate the environment
IS_VALID_ENV=false
for env in "${ALLOWED_ENVIRONMENTS[@]}"; do
  if [ "$env" == "$TARGET_ENV" ]; then
    IS_VALID_ENV=true
    break
  fi
done

if ! $IS_VALID_ENV; then
  log_error "Invalid environment specified: '$TARGET_ENV'. Allowed environments are: ${ALLOWED_ENVIRONMENTS[*]}"
fi

log_info "Target environment: $TARGET_ENV"
log_info "AWS CLI profile: $AWS_PROFILE_NAME"

# 3. Change to the infrastructure directory
if [ ! -d "$INFRA_DIR" ]; then
  log_error "Infrastructure directory './${INFRA_DIR}' not found. Please ensure it exists in the current path."
fi

log_info "Changing directory to './${INFRA_DIR}'..."
cd "$INFRA_DIR"
if [ "$?" -ne 0 ]; then # Check if cd was successful
    log_error "Failed to change directory to './${INFRA_DIR}'."
fi
log_info "Successfully changed directory to '$(pwd)'"


# 4. Define and check for the environment-specific variable file (now relative to INFRA_DIR)
VAR_FILE="${TARGET_ENV}.tfvars"
if [ ! -f "$VAR_FILE" ]; then
  log_error "Terraform variable file '$VAR_FILE' not found in './${INFRA_DIR}' for environment '$TARGET_ENV'."
fi
log_info "Using variable file: $VAR_FILE"

# 5. Set AWS_PROFILE environment variable for Terraform
export AWS_PROFILE="$AWS_PROFILE_NAME"
log_info "AWS_PROFILE set to '$AWS_PROFILE_NAME'"

# 6. Initialize Terraform (now runs inside INFRA_DIR)
log_info "Initializing Terraform in '$(pwd)'..."
if ! $TERRAFORM_CMD init; then
  log_error "Terraform init failed."
fi
log_info "Terraform initialized successfully."

# 7. Apply Terraform configuration (now runs inside INFRA_DIR)
log_info "Applying Terraform configuration for environment '$TARGET_ENV' from '$(pwd)'..."
# The -auto-approve flag automatically approves the changes.
# Remove it if you want to manually review the plan before applying.
if ! $TERRAFORM_CMD apply -var-file="$VAR_FILE" -auto-approve; then
  log_error "Terraform apply failed for environment '$TARGET_ENV'."
fi

log_info "Terraform apply completed successfully for environment '$TARGET_ENV'."
log_info "Infrastructure deployment for '$TARGET_ENV' using profile '$AWS_PROFILE_NAME' from './${INFRA_DIR}' is complete."

# Optional: Change back to the original directory if needed for subsequent script operations
# cd .. 

exit 0