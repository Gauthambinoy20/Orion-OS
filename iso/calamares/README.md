# Orion OS — Calamares installer config (M2, P#2.6)

This directory holds the Orion-specific Calamares configuration that
ships inside the installer ISO.

## What this delivers

- **LUKS2 default encryption**, pre-checked in the wizard.
- **Argon2id KDF**, 1 GiB memory cost, 2 s time cost — strong by
  default, completes in <2 s on every supported tier.
- **TPM2 enrollment** (best-effort) bound to PCR 7 (secure-boot
  policy), so unlock breaks on a tamper signal but survives kernel
  updates.
- **Mandatory passphrase fallback.** The original LUKS slot 0 is
  never touched. Plan §5.1 / §7.5 — non-negotiable.

## Files

| File | Purpose |
|---|---|
| `settings.conf` | Top-level Calamares sequence; inserts our TPM module between `initramfs` and `bootloader`. |
| `modules/partition.conf` | LUKS2 + argon2id defaults; pre-checks the encrypt box. |
| `modules/orion-tpm-enroll.conf` | Wires Calamares' shellprocess module to `tpm-enroll-luks`. |

The actual TPM enrollment script lives in the OS image at
`/usr/libexec/orion/tpm-enroll-luks` (added under
`image/files/usr/libexec/orion/`) so it is available both inside
the live ISO and on the installed system for re-enrollment.

## Activation in the ISO

`iso/isogenerator.yml` (P#1.5) will be updated in a follow-up commit
to copy this directory onto the live ISO at
`/etc/calamares/`. The split keeps this PR focused on the
configuration content and leaves ISO-build wiring as its own change.

## Smoke testing

The TPM enrollment script writes to `/var/log/orion-tpm-enroll.log`
so post-install smoke tests can grep that file for the success line.
A QEMU swtpm-backed smoke test is filed as a follow-up under M3.
