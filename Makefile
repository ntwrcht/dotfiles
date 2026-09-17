.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@printf "\033[1;36m🩺 Dotfiles Management\033[0m\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

.PHONY: install
install: ## Install or update all managed symlinks
	./install

.PHONY: uninstall
uninstall: ## Remove all managed symlinks and cleanup
	./uninstall

.PHONY: dry-run
dry-run: ## Preview symlink changes without applying
	./install --dry-run

.PHONY: doctor
doctor: ## Run diagnostic check on tools and environment
	./doctor

.PHONY: deps
deps: ## Install Homebrew dependencies from Brewfile
	brew bundle

.PHONY: docs
docs: ## Regenerate the generated sections of README.md
	./scripts/gen-readme-links

.PHONY: cleanup
cleanup: ## Preview orphaned Homebrew runtime candidates
	./cleanup-deps

.PHONY: cleanup-apply
cleanup-apply: ## Uninstall orphaned Homebrew runtime candidates
	./cleanup-deps --apply
