# Security Policy

Orion OS treats security as a release-blocking quality gate, not a feature
("verifiable claims" is one of our six strategic pillars — see
[`ORION_DEVELOPMENT_PLAN.md`](ORION_DEVELOPMENT_PLAN.md) §4 and §5.5).
This document explains how to report vulnerabilities and what you can
expect in return.

## Supported versions

Orion OS is in **pre-alpha (M0)**. There is no released image yet. Once a
version is released, this table will list which release lines receive
security updates.

| Version | Status | Security fixes |
|---|---|---|
| `main` (development) | active | yes — fixed at HEAD |
| `v0.x` (alpha/beta) | not yet released | n/a |
| `v1.x` (stable) | not yet released | n/a |

Pre-1.0 release branches (`v0.x`) are best-effort. Once `v1.0.0` ships, the
support window will be defined here.

## Reporting a vulnerability

**Please do not open a public GitHub issue for security problems.**

Use one of the following private channels:

1. **Preferred — GitHub Security Advisories.** Open a confidential report at
   <https://github.com/gauthambinoy/Orion-OS/security/advisories/new>.
   This routes directly to the maintainers and lets us collaborate with you
   on a fix and a coordinated disclosure.
2. **Encrypted email.** If you cannot use GitHub, contact the maintainer
   (@gauthambinoy) and request a PGP key for out-of-band reporting.

When you report, please include as much of the following as you can:

- A clear description of the issue and its impact
- The affected component (e.g. `orion-aid`, the OCI image, an installer flow)
- A minimal reproduction (commands, image hash, hardware tier)
- Any proof-of-concept code, screenshots, or logs
- Your assessment of severity (CVSS if you have it; rough words are fine)
- Whether you would like public credit, and under what name

## Our response commitments

| Stage | Target |
|---|---|
| Acknowledge receipt | within 72 hours |
| Initial triage and severity assessment | within 7 days |
| Status update cadence during investigation | at least every 14 days |
| Fix landed in `main` for confirmed High/Critical issues | within 30 days where feasible |
| Coordinated public disclosure | once a fix is shipped, or 90 days after report (whichever is sooner), unless mutually extended |

We will credit reporters in the advisory and the changelog unless you ask
us not to.

## Scope

In scope:

- The Orion OS image and any official derivatives shipped from this repo
- All first-party crates under `crates/`
- The build, sign, and release pipeline (`.github/workflows/`)
- The cosign trust root (`cosign.pub`) and any signed artifacts
- D-Bus interfaces exported by Orion daemons
- The default first-boot configuration, including AI routing and spend caps

Out of scope:

- Vulnerabilities in upstream Fedora, Universal Blue, KDE, the Linux kernel,
  or any third-party Flatpak. Please report those to the upstream project.
  We will gladly help coordinate if the issue is exposed by an Orion
  configuration choice.
- Issues that require an attacker who already has root or physical access
  to a fully-decrypted machine, unless they bypass an Orion-specific
  defence-in-depth control.
- Findings produced by automated scanners with no demonstrated impact.

## Our security model in one paragraph

Orion runs an atomic, signed OCI image (cosign-verified at install and
update time), enforces SELinux and a strict firewall by default, ships
LUKS2 + TPM2 with a *mandatory* passphrase fallback, sandboxes apps with
Flatpak and AI features with bubblewrap + landlock + seccomp, allows zero
outbound network from the AI daemon unless the user's chosen routing mode
permits it (Air-Gapped mode is verified by an `nftables` packet counter in
CI), forbids any background telemetry, and logs every cloud AI prompt to
a user-readable, encrypted local audit log. Full details live in
`docs/security-model.md` (added in milestone M2).

## Disclosure history

No advisories have been issued yet. Once they are, they will be linked here
and at <https://github.com/gauthambinoy/Orion-OS/security/advisories>.

## Hardening claims and CI

Every security promise in the plan is enforced by a CI gate before release
(see `ORION_DEVELOPMENT_PLAN.md` §5.5). If you find a way to make a release
artifact pass CI while violating one of those promises, that itself is a
reportable security issue.
