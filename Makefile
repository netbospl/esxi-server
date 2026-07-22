SHELL := /bin/bash

.PHONY: check check-local check-ci bash shellcheck markdown xml yaml packer tests secrets ignores links actionlint require-tool

check: check-local
check-local: bash shellcheck tests xml yaml packer markdown secrets ignores links actionlint
check-ci: REQUIRE_TOOLS=1
check-ci: check-local

require-tool:
	@command -v "$(TOOL)" >/dev/null 2>&1 || { if [[ "$(REQUIRE_TOOLS)" == 1 ]]; then echo "FAIL: required tool missing: $(TOOL)"; exit 127; else echo "NOT RUN: $(TOOL) is not installed"; exit 0; fi; }

bash:
	@set -euo pipefail; while IFS= read -r file; do bash -n "$$file"; done < <(git ls-files '*.sh'); echo 'PASS: Bash syntax'
shellcheck:
	@set -e; $(MAKE) require-tool TOOL=shellcheck REQUIRE_TOOLS=$(REQUIRE_TOOLS); if command -v shellcheck >/dev/null 2>&1; then git ls-files '*.sh' | xargs -r shellcheck; echo 'PASS: ShellCheck'; fi
tests:
	@set -euo pipefail; for test in tests/test-*.sh; do bash "$$test"; done
xml:
	@set -e; $(MAKE) require-tool TOOL=xmllint REQUIRE_TOOLS=$(REQUIRE_TOOLS); if command -v xmllint >/dev/null 2>&1; then for file in examples/guest-autoinstall/windows/*.xml; do xmllint --noout "$$file"; done; echo 'PASS: XML well-formedness'; fi
yaml:
	@set -e; $(MAKE) require-tool TOOL=cloud-init REQUIRE_TOOLS=$(REQUIRE_TOOLS); if command -v cloud-init >/dev/null 2>&1; then cloud-init schema --config-file examples/guest-autoinstall/linux/ubuntu/user-data; echo 'PASS: cloud-init schema'; fi
packer:
	@set -e; $(MAKE) require-tool TOOL=packer REQUIRE_TOOLS=$(REQUIRE_TOOLS); if command -v packer >/dev/null 2>&1; then packer init examples/guest-autoinstall/packer; packer fmt -check examples/guest-autoinstall/packer; for file in examples/guest-autoinstall/packer/*-vsphere-iso.pkr.hcl; do packer validate -syntax-only -var vcenter_server=example.invalid -var username=placeholder -var password=placeholder "$$file"; done; echo 'PASS: packer init, fmt, and validate'; fi
markdown:
	@set -e; $(MAKE) require-tool TOOL=markdownlint-cli2 REQUIRE_TOOLS=$(REQUIRE_TOOLS); if command -v markdownlint-cli2 >/dev/null 2>&1; then markdownlint-cli2 '**/*.md'; echo 'PASS: markdownlint-cli2'; fi
secrets:
	@set -e; $(MAKE) require-tool TOOL=gitleaks REQUIRE_TOOLS=$(REQUIRE_TOOLS); if command -v gitleaks >/dev/null 2>&1; then gitleaks detect --no-banner --source .; echo 'PASS: gitleaks'; fi
links:
	@set -e; $(MAKE) require-tool TOOL=lychee REQUIRE_TOOLS=$(REQUIRE_TOOLS); if command -v lychee >/dev/null 2>&1; then lychee --no-progress $$(git ls-files '*.md'); echo 'PASS: lychee'; fi
actionlint:
	@set -e; $(MAKE) require-tool TOOL=actionlint REQUIRE_TOOLS=$(REQUIRE_TOOLS); if command -v actionlint >/dev/null 2>&1; then actionlint; echo 'PASS: actionlint'; fi
ignores:
	@set -euo pipefail; for path in .ssh-known-hosts/esxi_known_hosts discovery-reports/example.json examples/guest-autoinstall/packer/local.pkrvars.hcl examples/guest-autoinstall/out/example.iso profiles/example.local.md; do git check-ignore -q "$$path" || { echo "FAIL: expected ignored: $$path"; exit 1; }; done; echo 'PASS: local artifacts ignored'