# Orion OS — Security Model

> Status: living document. Changes require a security ADR per plan §9.3.
> Last meaningful update: M2 (security baseline).

This document explains **what Orion OS protects, how, and where the
trust boundaries are.** Pair it with [`threat-model.md`](./threat-model.md)
which enumerates the adversaries we design against.

The goal is not "perfect security" — that does not exist. The goal is
to make the *easy* path the *safe* path for every user, and to make
the *hard* path explicit and auditable for the small number of users
who knowingly need to widen the surface.

---

## 1. Threat-class summary

| Threat class | Primary mitigation | Layer |
|---|---|---|
| Cold-boot disk theft | LUKS2 (argon2id) + TPM2 unlock + mandatory passphrase fallback | install / kernel |
| Malicious / compromised app | Flatpak deny-by-default + xdg-desktop-portal-kde | userspace |
| Malicious AI prompt-injection | bubblewrap-isolated `orion-aid` + per-action consent | AI subsystem (M4+) |
| Network MITM | DNS-over-TLS + DNSSEC allow-downgrade + signed updates | network |
| Hostile LAN scan | firewalld strict zone, drop inbound echo-request | network |
| Local privilege escalation | SELinux enforcing + hardened sysctls + landlock+seccomp on daemons | kernel |
| Supply-chain compromise | reproducible builds + cosign-signed images + SBOM attestation | build |
| Telemetry / surveillance | **Zero telemetry, ever.** No opt-out toggle because nothing to opt out of | policy |

Each row maps to one or more landed commits; see the per-section
links below.

---

## 2. Trust boundaries

```
┌──────────────────────────────────────────────────────────────┐
│  USER (passphrase, hardware tokens, KWallet master key)      │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  KDE SESSION (per-user; SELinux user_u + landlock)     │  │
│  │                                                        │  │
│  │  ┌──────────────────┐  ┌──────────────────────────┐    │  │
│  │  │ FLATPAK APPS     │  │ NATIVE APPS              │    │  │
│  │  │ deny-by-default  │  │ SELinux confined         │    │  │
│  │  │ portal-mediated  │  │ flatpak-restricted PATH  │    │  │
│  │  └──────────────────┘  └──────────────────────────┘    │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │ AI SUBSYSTEM (orion-aid + helpers)               │  │  │
│  │  │ bubblewrap; air-gap firewall rule for UID;       │  │  │
│  │  │ explicit per-action consent before destructive   │  │  │
│  │  │ ops; cloud routes only when user-keyed           │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  SYSTEM (rpm-ostree immutable; SELinux enforcing)      │  │
│  │  cosign-verified base + layered packages only          │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  KERNEL (CachyOS; KASLR + hardened sysctls)            │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  FIRMWARE / TPM (PCR 7 binding for unattended unlock)  │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

A successful attack on a layer should not implicitly compromise
layers below it. Defense in depth is mandatory at every boundary.

---

## 3. Layer-by-layer controls

### 3.1 Disk

- **LUKS2 with argon2id** (1 GiB memory, 2 s time) on every default
  install. See `iso/calamares/modules/partition.conf`.
- **TPM2 unlock bound to PCR 7** (secure-boot policy). Tamper signal
  preserved, kernel updates do not break unlock. See
  `image/files/usr/libexec/orion/tpm-enroll-luks`.
- **Mandatory passphrase fallback.** Slot 0 is never touched. The
  enrollment script verifies slot 0 exists and aborts loudly if it
  does not. Plan §5.1 / §7.5 — non-negotiable.

### 3.2 Kernel

- **SELinux enforcing + targeted** (`image/files/etc/selinux/config`).
- **CIS-aligned sysctls** in `99-orion-hardening.conf`:
  kptr_restrict=2, dmesg_restrict=1, perf_event_paranoid=3,
  yama.ptrace_scope=1, kexec_load_disabled=1,
  unprivileged_bpf_disabled=1, bpf_jit_harden=2,
  unprivileged_userfaultfd=0, suid_dumpable=0,
  protected_symlinks/hardlinks/fifos/regular, network anti-spoofing
  for v4 and v6, randomize_va_space=2, mmap_min_addr=64KiB.
- Updates ship the **CachyOS kernel** (M3) for the BORE scheduler;
  hardening posture remains identical.

### 3.3 Network

- **firewalld strict zone** (`orion`): deny inbound; allow only
  dhcpv6-client, mdns, ssh; drop inbound echo-request. See
  `image/files/etc/firewalld/zones/orion.xml`.
- **DNS-over-TLS** via systemd-resolved with three diverse upstreams
  (Quad9, Cloudflare, Google). DNSSEC allow-downgrade for
  captive-portal compatibility. See `orion-doh.conf`.
- **Air-Gapped AI mode** (M4) layers an additional firewall rule set
  that drops all egress for the orion-aid UID. Air-gap leak test in
  CI is a release blocker (plan §5.5).

### 3.4 Userspace apps

- **Flatpak deny-by-default global override** revokes
  filesystem=host/host-os/host-etc/home, devices=all, bus +
  cups/pcsc/gpg-agent/ssh-auth sockets, network shared, devel +
  multiarch + bluetooth + canbus features, and strips LD_PRELOAD.
  Apps regain access only through portals or explicit `flatpak
  override`.
- **Flathub filtered to verified publishers** by default. Users opt
  in to the full catalogue.
- **Bubblewrap** sandbox on all AI helper processes (M4).
- **landlock + seccomp** on every Orion-shipped Rust daemon.

### 3.5 AI subsystem (preview — full spec lands with M4)

- `orion-aid` runs under a dedicated unprivileged UID with
  bubblewrap, landlock writeable paths limited to its own state dir,
  and a seccomp policy auto-derived from its syscall set.
- Cloud routes are off by default. When enabled, API keys live in
  KWallet — not on disk in plaintext.
- All destructive actions (file delete/move, command execution from
  NL Launcher) require explicit per-action user confirmation. A
  prompt-injection attack reaches a confirmation dialog, not a
  successful action.

### 3.6 Build & supply chain

- **Reproducible OCI builds** via BlueBuild on GHCR.
- **Cosign signature** by digest on every push. See
  `.github/workflows/build-image.yml`.
- **Release-time SBOM** in SPDX + CycloneDX, signed with `cosign
  attest`. See `.github/workflows/sign-release.yml`.
- **Trivy CVE scan** of every image; HIGH or CRITICAL fails the
  build. See `.github/workflows/security-scan.yml`.
- **Lynis hardening score >= 90** is a release blocker.

### 3.7 Telemetry

We collect **nothing**. There is no telemetry endpoint, no opt-in
flag, no anonymous metrics, no error reports phoning home. If a
future commit introduces any outbound connection that is not the
result of an explicit user action or a signed update check, treat it
as a P0 bug and revert.

---

## 4. User-controllable knobs (and why each exists)

| Knob | Default | Why this default | How to flip |
|---|---|---|---|
| AI routing mode | Privacy First | Local-first matches the marketing pillar | first-boot wizard or KCM |
| Flathub filter | verified-only | Most users want curated; power users want firehose | Discover → Sources |
| TPM2 unlock | enabled if TPM present | Better UX with no security regression | `systemd-cryptenroll --wipe-slot=tpm2` |
| Air-gap mode | off | Network is needed for updates | KCM AI panel |
| Telemetry | off | Always | n/a — no opt-in exists |

---

## 5. References

- Plan §5.1 — frozen stack
- Plan §5.4 — AI routing modes
- Plan §5.5 — release-blocking quality gates
- Plan §7.5 — security rules
- [`threat-model.md`](./threat-model.md) — adversary catalogue
