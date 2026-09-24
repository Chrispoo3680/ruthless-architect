.PHONY: check doctor install install-copy uninstall package

check:
	bash -n scripts/*.sh
	test -f SKILL.md
	test -f references/claude-runtime.md
	test -f references/codex-runtime.md
	test -f references/gemini-runtime.md
	test -f references/local-worker.md
	grep -q '^name: ruthless-architect$$' SKILL.md

doctor:
	./scripts/doctor.sh

install:
	./scripts/install.sh

install-copy:
	./scripts/install.sh --copy

uninstall:
	./scripts/uninstall.sh

package:
	@version=$$(cat VERSION); name=$$(basename "$$(pwd)"); parent=$$(dirname "$$(pwd)"); \
	(cd "$$parent" && zip -qr "ruthless-architect-github-v$$version.zip" "$$name" -x '*/.git/*' '*.zip')
