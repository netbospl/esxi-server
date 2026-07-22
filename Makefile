SHELL := /bin/bash

.PHONY: check bash shellcheck markdown xml yaml packer tests secrets ignores

check: bash shellcheck tests xml yaml packer markdown secrets ignores

bash:
	@set -euo pipefail; while IFS= read -r file; do bash -n "$$file"; done < <(git ls-files '*.sh'); echo 'PASS: Bash syntax'

shellcheck:
	@set -euo pipefail; if command -v shellcheck >/dev/null 2>&1; then git ls-files '*.sh' | xargs -r shellcheck; echo 'PASS: ShellCheck'; else echo 'NOT RUN: ShellCheck is not installed'; fi

tests:
	@set -euo pipefail; for test in tests/test-*.sh; do bash "$$test"; done

xml:
	@set -euo pipefail; while IFS= read -r file; do xmllint --noout "$$file"; done < <(git ls-files '*.xml'); echo 'PASS: XML well-formedness'

yaml:
	@set -euo pipefail; if command -v cloud-init >/dev/null 2>&1; then cloud-init schema --config-file examples/guest-autoinstall/linux/ubuntu/user-data; echo 'PASS: cloud-init schema'; else echo 'NOT RUN: cloud-init schema is not installed'; fi

packer:
	@set -euo pipefail; if command -v packer >/dev/null 2>&1; then packer fmt -check examples/guest-autoinstall/packer; for file in examples/guest-autoinstall/packer/*-vsphere-iso.pkr.hcl; do packer validate -syntax-only -var vcenter_server=example.invalid -var username=placeholder -var password=placeholder "$$file"; done; echo 'PASS: packer fmt and syntax-only validate'; else echo 'NOT RUN: Packer is not installed'; fi

markdown:
	@set -euo pipefail; if command -v markdownlint >/dev/null 2>&1; then git ls-files '*.md' | xargs -r markdownlint; echo 'PASS: markdownlint'; else echo 'NOT RUN: markdownlint is not installed'; fi

secrets:
	@set -euo pipefail; if command -v gitleaks >/dev/null 2>&1; then gitleaks detect --no-banner --source .; echo 'PASS: gitleaks'; else echo 'NOT RUN: gitleaks is not installed'; fi

ignores:
	@set -euo pipefail; for path in .ssh-known-hosts/esxi_known_hosts discovery-reports/example.json examples/guest-autoinstall/packer/local.pkrvars.hcl examples/guest-autoinstall/out/example.iso profiles/example.local.md; do git check-ignore -q "$$path" || { echo "FAIL: expected ignored: $$path"; exit 1; }; done; echo 'PASS: local artifacts ignored'