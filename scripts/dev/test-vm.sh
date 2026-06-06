#!/usr/bin/env bash
# Orion OS — local QEMU test runner (M1, P#1.7)
#
# Boots a built Orion image inside QEMU/KVM and lets the developer
# either eyeball the desktop or hand the VM off to the smoke-test
# scripts (P#1.10). The CI VM smoke job uses the same script so what
# passes locally passes on a runner.
#
# Strategy:
#   1. Convert the rootfs from the OCI image into a qcow2 disk via
#      bootc-image-builder (Aurora's standard tool for this; produces
#      bootable qcow2s for atomic OSTree systems without needing
#      Anaconda).
#   2. Boot it in QEMU with KVM if available, TCG fallback otherwise so
#      the script still works on Mac CI runners and weird hosts.
#   3. Wait for SSH on a forwarded port; print the connection details
#      and exit (or, in --smoke mode, run the smoke-test script and
#      tear the VM down).
#
# Usage:
#   scripts/dev/test-vm.sh                       # uses orion:dev
#   scripts/dev/test-vm.sh ghcr.io/owner/orion:latest
#   scripts/dev/test-vm.sh --smoke orion:dev     # boot + run smoke + halt
#
# Plan ref: M1 P#1.7; CI consumer arrives in P#1.10.

set -euo pipefail

# --- defaults ---
IMAGE="${1:-orion:dev}"
SMOKE=0
if [[ "${IMAGE}" == "--smoke" ]]; then
    SMOKE=1
    IMAGE="${2:-orion:dev}"
fi

WORK_DIR="${ORION_VM_WORK_DIR:-/tmp/orion-vm}"
DISK_PATH="${WORK_DIR}/orion.qcow2"
SSH_PORT="${ORION_VM_SSH_PORT:-2222}"
MEM_MB="${ORION_VM_MEM_MB:-4096}"
CPUS="${ORION_VM_CPUS:-2}"

# --- preflight ---
need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "missing required tool: $1" >&2
        echo "install hint: $2" >&2
        exit 1
    }
}

need qemu-system-x86_64 "apt install qemu-system-x86 / dnf install qemu-system-x86"
need podman             "apt install podman / dnf install podman"
need ssh                "openssh-client (almost certainly already installed)"

mkdir -p "${WORK_DIR}"

# --- 1. build the qcow2 from the OCI image ---
# bootc-image-builder runs as a privileged container that writes the
# disk image into the work dir. We pin the version so a surprise
# upstream change cannot break this script.
BIB_IMAGE="quay.io/centos-bootc/bootc-image-builder:0.1.4"

if [[ ! -f "${DISK_PATH}" ]] || [[ -n "${ORION_VM_REBUILD:-}" ]]; then
    echo "==> Building qcow2 from ${IMAGE} (this can take a few minutes)"
    podman run --rm -it \
        --privileged \
        --pull=newer \
        --security-opt label=type:unconfined_t \
        -v "${WORK_DIR}:/output" \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        "${BIB_IMAGE}" \
        --type qcow2 \
        --rootfs ext4 \
        "${IMAGE}"

    # bootc-image-builder writes to qcow2/disk.qcow2 by convention.
    if [[ -f "${WORK_DIR}/qcow2/disk.qcow2" ]]; then
        mv "${WORK_DIR}/qcow2/disk.qcow2" "${DISK_PATH}"
        rmdir "${WORK_DIR}/qcow2" 2>/dev/null || true
    fi
fi

[[ -f "${DISK_PATH}" ]] || {
    echo "qcow2 build did not produce ${DISK_PATH}" >&2
    exit 1
}

# --- 2. boot ---
ACCEL_FLAGS=()
if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
    ACCEL_FLAGS=(-enable-kvm -cpu host)
else
    echo "==> /dev/kvm unavailable; falling back to TCG (slow). This is normal on CI."
    ACCEL_FLAGS=(-cpu max)
fi

echo "==> Booting Orion VM (ssh: localhost:${SSH_PORT})"
QEMU_PIDFILE="${WORK_DIR}/qemu.pid"

qemu-system-x86_64 \
    "${ACCEL_FLAGS[@]}" \
    -m "${MEM_MB}" \
    -smp "${CPUS}" \
    -drive "file=${DISK_PATH},if=virtio,format=qcow2" \
    -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22" \
    -device "virtio-net-pci,netdev=net0" \
    -nographic \
    -serial mon:stdio \
    -pidfile "${QEMU_PIDFILE}" \
    -daemonize

trap 'kill "$(cat "${QEMU_PIDFILE}" 2>/dev/null)" 2>/dev/null || true' EXIT

# --- 3. wait for ssh ---
echo -n "==> Waiting for ssh on :${SSH_PORT} "
for i in $(seq 1 120); do
    if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null -p "${SSH_PORT}" \
           orion@localhost true 2>/dev/null; then
        echo " up."
        break
    fi
    echo -n "."
    sleep 2
    if [[ $i -eq 120 ]]; then
        echo " timed out." >&2
        exit 1
    fi
done

if [[ "${SMOKE}" -eq 1 ]]; then
    echo "==> Running smoke tests"
    if [[ -d tests/smoke ]]; then
        for s in tests/smoke/*.sh; do
            echo "--- ${s} ---"
            ORION_VM_SSH_PORT="${SSH_PORT}" bash "${s}"
        done
    else
        echo "tests/smoke not present yet; rerun once P#1.10 lands." >&2
        exit 1
    fi
    echo "==> Smoke tests passed."
else
    echo "==> VM is up. Connect with:"
    echo "    ssh -p ${SSH_PORT} orion@localhost"
    echo "==> Press Ctrl-C to stop the VM."
    # Keep the trap alive until the user kills us.
    wait "$(cat "${QEMU_PIDFILE}")" 2>/dev/null || true
fi
