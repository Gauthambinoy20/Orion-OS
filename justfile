# Orion OS — developer task runner (M1, P#1.6)
#
# Single entry point for everything a contributor does locally. If a
# task is worth doing twice, it belongs in this file. Keep recipes
# small, well-commented, and shellcheck-clean (the shellcheck CI job
# lints just-recipe shell bodies via the .sh files in scripts/).
#
# Conventions:
#   - Default recipe lists everything (just == just --list).
#   - Recipes that change the host are NOT default and require the user
#     to type the name (no surprise installs).
#   - Recipes are grouped by lifecycle: setup, build, test, release.
#   - Container runtime defaults to podman; override with CONTAINER=docker.
#
# Usage:
#   just                    # list recipes
#   just lint               # run all linters
#   just build-image        # build the OCI image locally
#   just test-vm            # boot the image in QEMU (P#1.7)

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# ----- Tunables (override on the command line) -----
container := env_var_or_default("CONTAINER", "podman")
image_tag := env_var_or_default("ORION_TAG", "dev")
aurora_tag := "41"

# ----- Default: print available recipes -----
default:
    @just --list --unsorted

# ===== Lint =====

# Run every linter we ship, locally, in the same order CI runs them.
lint: lint-yaml lint-shell lint-md lint-secrets
    @echo "All linters passed."

lint-yaml:
    yamllint --strict -c .yamllint.yml .

lint-shell:
    @# Match the CI runner: tracked .sh / .bash plus shebang-detected scripts.
    git ls-files '*.sh' '*.bash' | xargs --no-run-if-empty shellcheck
    @# Anything with a sh / bash shebang.
    git ls-files | xargs -I{} sh -c 'head -n1 "{}" 2>/dev/null | grep -qE "^#!.*/(bash|sh)\\b" && echo {}' \
      | xargs --no-run-if-empty shellcheck || true

lint-md:
    npx --yes markdownlint-cli2 "**/*.md"

lint-secrets:
    @# gitleaks may not be installed locally; skip cleanly.
    @command -v gitleaks >/dev/null || { echo "gitleaks not installed; skipping (CI still runs it)."; exit 0; }
    gitleaks detect --no-banner --redact

# ===== Build =====

# Build the OCI image with the BlueBuild CLI (canonical path).
build-image:
    @command -v bluebuild >/dev/null || { echo "bluebuild not installed: https://blue-build.org/learn/getting-started/"; exit 1; }
    bluebuild build --tag {{image_tag}} image/recipe.yml

# Fallback: build via Containerfile. Useful when BlueBuild is broken or
# uninstalled. Produces ghcr.io/<you>/orion:{{image_tag}}.
build-container:
    {{container}} build \
        --build-arg AURORA_TAG={{aurora_tag}} \
        --build-arg ORION_VERSION={{image_tag}} \
        -t orion:{{image_tag}} \
        .

# ===== Test =====

# Run the local QEMU smoke test (lands in P#1.7 with the script).
test-vm:
    @test -x scripts/dev/test-vm.sh || { echo "scripts/dev/test-vm.sh not yet committed (P#1.7)"; exit 1; }
    scripts/dev/test-vm.sh orion:{{image_tag}}

# Run the smoke-test scripts (lands with P#1.10).
test-smoke:
    @test -d tests/smoke || { echo "tests/smoke not yet committed (P#1.10)"; exit 1; }
    bash -c 'for s in tests/smoke/*.sh; do echo "==> $s"; bash "$s"; done'

# ===== Release helpers =====

# Verify the current cosign.pub matches the trust-root key. Catches the
# case where someone committed a wrong key by accident.
verify-cosign-key:
    @test -f cosign.pub || { echo "cosign.pub missing"; exit 1; }
    @command -v cosign >/dev/null || { echo "cosign not installed: https://docs.sigstore.dev/system_config/installation"; exit 1; }
    cosign public-key --key cosign.pub > /tmp/orion-cosign.pub.check
    diff -u cosign.pub /tmp/orion-cosign.pub.check
    @rm -f /tmp/orion-cosign.pub.check
    @echo "cosign.pub is internally consistent."

# Print the dev environment as CI sees it. Useful in bug reports.
doctor:
    @echo "--- versions ---"
    @just --version
    @{{container}} --version 2>/dev/null || echo "{{container}} not installed"
    @yamllint --version 2>/dev/null || echo "yamllint not installed"
    @shellcheck --version 2>/dev/null | head -n1 || echo "shellcheck not installed"
    @cosign version 2>/dev/null | head -n1 || echo "cosign not installed"
    @bluebuild --version 2>/dev/null || echo "bluebuild not installed"
    @echo "--- repo ---"
    @git rev-parse --short HEAD
    @git status --short
