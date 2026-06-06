#!/usr/bin/env bash
# Orion OS — repository integrity checks.
#
# Fast, dependency-light assertions that pin the invariants whose breakage
# previously failed the image build. Each check maps to a real failure we
# hit so it can never silently regress. Runs in the lint workflow (no
# image build, no network) and locally via `just test-repo`.
#
# Checks:
#   1. os-release VERSION_ID matches the recipe's base-image major
#      (a mismatch makes dnf resolve $releasever to the wrong repo).
#   2. os-release is pure KEY=VALUE (a '#' comment broke bootc-image
#      -builder's readOSRelease parser).
#   3. every files-module `source:` exists under files/.
#   4. every recipe.yml `from-file:` target exists under recipes/.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

RECIPE="recipes/recipe.yml"
OSREL="files/etc/os-release"
fails=0
fail() { echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok()   { echo "ok: $*"; }

# 1. VERSION_ID must equal the aurora-dx image-version (the Fedora major).
base_major="$(awk -F'"' '/^image-version:/ {print $2}' "${RECIPE}")"
os_version_id="$(awk -F= '/^VERSION_ID=/ {gsub(/"/,"",$2); print $2}' "${OSREL}")"
if [[ -z "${base_major}" ]]; then
    fail "could not read image-version from ${RECIPE}"
elif [[ "${base_major}" != "${os_version_id}" ]]; then
    fail "os-release VERSION_ID=${os_version_id} != recipe image-version=${base_major}"
else
    ok "VERSION_ID matches base major (${base_major})"
fi

# 2. os-release must be comment-free KEY=VALUE lines (blank lines allowed).
if grep -qE '^[[:space:]]*#' "${OSREL}"; then
    fail "${OSREL} contains a comment line; readOSRelease rejects non KEY=VALUE lines"
elif grep -vqE '^[[:space:]]*$|^[A-Z_]+=' "${OSREL}"; then
    fail "${OSREL} has a line that is neither blank nor KEY=VALUE"
else
    ok "os-release is clean KEY=VALUE"
fi

# 3. every files-module source: path must exist under files/.
missing_src=0
while read -r src; do
    [[ -z "${src}" ]] && continue
    if [[ ! -e "files/${src}" ]]; then
        fail "recipe references missing file: files/${src}"
        missing_src=$((missing_src + 1))
    fi
done < <(grep -rhoE '^\s*-?\s*source:\s*\S+' recipes/ | awk '{print $NF}')
[[ "${missing_src}" -eq 0 ]] && ok "all files-module sources exist under files/"

# 4. every from-file target must exist under recipes/.
missing_mod=0
while read -r mod; do
    [[ -z "${mod}" ]] && continue
    if [[ ! -f "recipes/${mod}" ]]; then
        fail "recipe.yml from-file target missing: recipes/${mod}"
        missing_mod=$((missing_mod + 1))
    fi
done < <(awk '/^\s*-\s*from-file:/ {print $NF}' "${RECIPE}")
[[ "${missing_mod}" -eq 0 ]] && ok "all from-file targets exist under recipes/"

if [[ "${fails}" -ne 0 ]]; then
    echo "${fails} integrity check(s) failed." >&2
    exit 1
fi
echo "All repository integrity checks passed."
