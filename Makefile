PYTHON = python3
PIP = $(PYTHON) -m pip

SHARED_MODULE_DIR = ./app/shared

install-shared:
	@echo "Installing module at $(SHARED_MODULE_DIR) in editable mode..."
	$(PIP) install -e $(SHARED_MODULE_DIR)
	@echo "Shared module installed."
	@echo "Removing egg and egg-info files..."
	@rm -rf $(SHARED_MODULE_DIR)/*.egg $(SHARED_MODULE_DIR)/*.egg-info

.PHONY: install-shared