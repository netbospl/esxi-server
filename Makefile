SHELL := /bin/bash

.PHONY: check
check:
	@set -u; \
	echo '== markdownlint =='; \
	if command -v markdownlint >/dev/null 2>&1; then markdownlint SKILL.md README.md AGENTS.md docs/*.md references/*.md profiles/*.md templates/*.md; else echo 'markdownlint not installed'; fi; \
	echo '== shellcheck =='; \
	if command -v shellcheck >/dev/null 2>&1; then shellcheck scripts/esxi-readonly-discovery.sh; else echo 'shellcheck not installed'; fi; \
	echo '== secret scan =='; \
	if command -v gitleaks >/dev/null 2>&1; then gitleaks detect --no-banner --source .; \
	elif command -v trufflehog >/dev/null 2>&1; then trufflehog filesystem .; \
	else echo 'gitleaks/trufflehog not installed'; fi; \
	echo '== obvious private key grep =='; \
	grep -R --line-number --binary-files=without-match -E 'BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY' . || true
