#!/usr/bin/env bash
# Orion OS — smoke test 01: the VM boots and identifies as Orion (M1, P#1.10)
#
# This is the lowest-bar smoke test we can write: SSH into the running
# VM, ask it who it is, and assert the answer matches the identity
# files we shipped in P#1.1 / P#1.2.
#
# It runs in two contexts:
#   - Locally:  invoked by scripts/dev/test-vm.sh --smoke
#   - In CI:    invoked by .github/workflows/test-vm.yml
#
# Both contexts pre-boot the VM and forward SSH on $ORION_VM_SSH_PORT
# (default 2222), so the only thing this script does is talk to that
# already-running SSH server.
#
# Plan ref: M1 P#1.10. See plan section 5.5 (quality gates) for why
# every milestone must end with at least one bootable check.

set -euo pipefail

PORT="${ORION_VM_SSH_PORT:-2222}"
USER_NAME="${ORION_VM_SSH_USER:-orion}"
HOST="${ORION_VM_SSH_HOST:-localhost}"

ssh_run() {
    ssh -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        -p "${PORT}" "${USER_NAME}@${HOST}" "$@"
}

assert_contains() {
    local needle="$1"
    local haystack="$2"
    local label="$3"
    if [[ "${haystack}" != *"${needle}"* ]]; then
        echo "FAIL: ${label}: expected to contain '${needle}'" >&2
        echo "  got: ${haystack}" >&2
        exit 1
    fi
    echo "ok: ${label}"
}

echo "==> 01-boots: probing VM at ${USER_NAME}@${HOST}:${PORT}"

# 1. /etc/os-release identifies as Orion.
OS_RELEASE="$(ssh_run cat /etc/os-release)"
assert_contains 'ID=orion'                "${OS_RELEASE}" "ID=orion in os-release"
assert_contains 'NAME="Orion OS"'         "${OS_RELEASE}" "NAME in os-release"
assert_contains 'VARIANT_ID=orion'        "${OS_RELEASE}" "VARIANT_ID in os-release"

# 2. Our additional identity file exists.
ssh_run test -f /etc/orion-release
echo "ok: /etc/orion-release exists"

# 3. The kernel is running and reports a sane uptime (sanity that the
#    image actually booted, not just that we are talking to a chroot).
UPTIME_S="$(ssh_run cat /proc/uptime | awk '{print int($1)}')"
if [[ "${UPTIME_S}" -lt 1 ]]; then
    echo "FAIL: kernel reports uptime ${UPTIME_S}s; VM did not actually boot?" >&2
    exit 1
fi
echo "ok: kernel uptime ${UPTIME_S}s"

# 4. The base CLI tools we promised in image/recipes/base.yml are present.
for tool in git just jq rg fd age; do
    if ssh_run "command -v ${tool}" >/dev/null; then
        echo "ok: ${tool} installed"
    else
        echo "FAIL: required base tool missing: ${tool}" >&2
        exit 1
    fi
done

# 5. KDE is present (we don't start a session here, just check the
#    binary exists; full KDE smoke lands with the desktop work in M2+).
if ssh_run "command -v plasmashell" >/dev/null; then
    echo "ok: plasmashell installed"
else
    echo "FAIL: plasmashell missing; KDE module did not apply?" >&2
    exit 1
fi

# 6. The PIM apps we deliberately removed in image/recipes/kde.yml are
#    actually gone.
for removed in kmail akregator korganizer kontact; do
    if ssh_run "command -v ${removed}" >/dev/null 2>&1; then
        echo "FAIL: ${removed} should have been removed by kde.yml" >&2
        exit 1
    fi
done
echo "ok: KDE PIM stack absent as intended"

echo "==> 01-boots: PASS"
