.PHONY: self-audit pre-commit-check pre-push-check install-hooks

self-audit: pre-commit-check pre-push-check

pre-commit-check:
	@.husky/pre-commit

pre-push-check:
	@.husky/pre-push

install-hooks:
	@chmod +x .husky/pre-commit .husky/pre-push
	@git config core.hooksPath .husky
	@echo "✓ Hooks installed (git config core.hooksPath .husky)"
