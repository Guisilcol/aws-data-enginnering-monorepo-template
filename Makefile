PYTHON = python3
PIP = $(PYTHON) -m pip

SHARED_MODULE_DIR = ./app/shared

install-shared:
	@echo "Installing module at $(SHARED_MODULE_DIR) in editable mode..."
	$(PIP) install -e $(SHARED_MODULE_DIR)
	@echo "Shared module installed."
	@echo "Removing egg and egg-info files..."
	@rm -rf $(SHARED_MODULE_DIR)/*.egg $(SHARED_MODULE_DIR)/*.egg-info

build:
	@echo "Building Glue..."
	bash ./cicd/build-glue.sh
	@echo "Building Lambda"
	bash ./cicd/build-lambda.sh
	@echo "Building shared module"
	bash ./cicd/build-shared.sh
	@echo "Building Step Functions"
	bash ./cicd/build-stepfunctions.sh

.PHONY: install-shared build