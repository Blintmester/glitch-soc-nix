SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

SYSTEM ?= x86_64-linux
TAG    ?=
FORGE  ?= https://codeberg.org
OWNER  ?= tutter
REPO   ?= glitch-soc-nix
BASE   ?= main

BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
GENERATED := flake.nix gemset.nix yarn-missing-hashes.json

.PHONY: help current latest outdated update refresh build check pr push clean

help: ## Show available targets
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk -F':.*?## ' '{printf "  \033[36m%-9s\033[0m %s\n", $$1, $$2}'

current: ## Print the packaged glitch-soc version (as a tag)
	@echo "v$$(sed -n 's/^ *version = "\(.*\)";.*/\1/p' flake.nix | head -1)"

latest: ## Print the latest upstream glitch-soc tag
	@git ls-remote --tags --refs https://github.com/glitch-soc/mastodon 'v*' \
		| awk '{print $$2}' | sed 's|refs/tags/||' \
		| grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$$' | sort -V | tail -1

outdated: ## Exit 0 if an upstream update is available, 1 otherwise
	@test "$$($(MAKE) --no-print-directory current)" != "$$($(MAKE) --no-print-directory latest)"

update: ## Follow the latest upstream tag (or TAG=v4.6.4 for a specific one)
	./update.sh $(TAG)

refresh: ## Regenerate everything for the version currently set in flake.nix
	./update.sh --refresh

build: ## Build the package for SYSTEM (needs a matching builder)
	nix build --no-link --print-out-paths .#packages.$(SYSTEM).default

check: ## Evaluate the package without building it
	@nix eval --raw .#packages.$(SYSTEM).default.drvPath && echo

pr: ## Commit on a branch and open a pull request (needs FORGE_TOKEN)
	@test -n "$(FORGE_TOKEN)" || { echo "FORGE_TOKEN is not set"; exit 1; }
	@version="$$($(MAKE) --no-print-directory current)"; \
	branch="update/$$version"; \
	git checkout -B "$$branch"; \
	git add $(GENERATED); \
	git -c user.name="woodpecker" -c user.email="ci@$(OWNER).noreply" \
		commit -m "update to glitch-soc $$version"; \
	push_url="$$(printf '%s' '$(FORGE)' | sed 's|://|://oauth2:$(FORGE_TOKEN)@|')/$(OWNER)/$(REPO).git"; \
	git push --force "$$push_url" "$$branch" 2>&1 | sed 's|://[^@]*@|://|g'; \
	curl -sS -X POST "$(FORGE)/api/v1/repos/$(OWNER)/$(REPO)/pulls" \
		-H "Authorization: token $(FORGE_TOKEN)" \
		-H "Content-Type: application/json" \
		-d "{\"head\":\"$$branch\",\"base\":\"$(BASE)\",\"title\":\"update to glitch-soc $$version\",\"body\":\"Automated update, verified with a full nix build on the CI runner.\"}" \
		| grep -o '"html_url":"[^"]*"' | head -1 \
		|| echo "no pull request created (one may already be open for $$branch)"

push: ## Commit regenerated files onto BRANCH and push (needs FORGE_TOKEN)
	@test -n "$(FORGE_TOKEN)" || { echo "FORGE_TOKEN is not set"; exit 1; }
	@test -n "$(BRANCH)" || { echo "BRANCH is not set"; exit 1; }
	@if git diff --quiet -- $(GENERATED); then \
		echo "nothing to commit, hashes already match"; \
	else \
		version="$$($(MAKE) --no-print-directory current)"; \
		git add $(GENERATED); \
		git -c user.name="woodpecker" -c user.email="ci@$(OWNER).noreply" \
			commit -m "regenerate sources for glitch-soc $$version"; \
		push_url="$$(printf '%s' '$(FORGE)' | sed 's|://|://oauth2:$(FORGE_TOKEN)@|')/$(OWNER)/$(REPO).git"; \
		git push "$$push_url" "HEAD:refs/heads/$(BRANCH)" 2>&1 | sed 's|://[^@]*@|://|g'; \
	fi

clean: ## Remove build artifacts and the checked-out upstream source
	rm -rf glitch-soc-src result
