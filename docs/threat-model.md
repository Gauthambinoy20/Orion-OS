# Orion OS — Threat Model

> Status: living document. Pair with [`security-model.md`](./security-model.md)
> for the controls that mitigate each threat below.

This document enumerates the **adversaries** Orion OS is designed
against, in priority order. For each adversary it states the
**capabilities** we assume, the **goals** we believe they pursue, and
the **controls** we ship to disrupt them.

We use a STRIDE-flavoured framing per adversary rather than per asset
because the user-visible question is "who is trying to do what to me",
not "which CIA letter applies to this row of the database."

---

## 1. Adversaries (in priority order)

### A1 — Opportunistic disk-recovery attacker

**Scenario:** laptop stolen / lost / sold without a wipe.

**Capabilities:** physical access to the powered-off device, weeks of
offline analysis time, commodity GPU cluster.

**Goal:** read user data (browser session, mail, photos, KWallet,
SSH keys, AI chat history).

**Why we rate this A1:** every user with a laptop is in this threat
model. It is the single most likely real attack any Orion install
will ever face.

**Controls:**

- Default LUKS2 with argon2id (1 GiB, 2 s) — commodity-GPU resistant.
- TPM2 unlock bound to PCR 7. If the attacker swaps the disk into a
  different machine the TPM does not unseal. If they tamper with
  secure-boot keys to coerce unlock, PCR 7 changes and the unseal
  fails. They fall back to needing the passphrase.
- AI vector store encrypted with `age` (M5/M7) — even with disk
  decrypted, the embeddings index is a separate trust boundary.
- KWallet for API keys and tokens (M4+).

**Residual risk:** an attacker who *also* has the user's passphrase
wins. We accept this — it is a credential-theft problem, not a
disk-encryption problem.

---

### A2 — Hostile network on a coffee-shop / conference / hotel LAN

**Scenario:** user opens the laptop on an untrusted Wi-Fi.

**Capabilities:** full L2 control of the LAN, DNS spoofing, ARP
poisoning, captive-portal MITM, port-scanning, ICMP probing, can
serve crafted content over HTTP.

**Goal:** identify the host, exploit any exposed service, harvest
DNS queries, downgrade to plaintext.

**Controls:**

- firewalld strict zone: deny inbound; only mdns + ssh exposed and
  ssh is normally not actually running.
- Inbound ICMP echo-request blocked → host does not advertise.
- DNS-over-TLS with three diverse upstreams + DNSSEC allow-downgrade.
  Captive portals work; fully-spoofed DNS does not.
- Hardened sysctls: `accept_redirects=0`, `accept_source_route=0`,
  `rp_filter=1`, `tcp_syncookies=1`, `tcp_rfc1337=1`, IPv6 routing
  disabled (`accept_ra=0`).
- Updates via cosign-verified images only. A spoofed mirror cannot
  feed a malicious update.

**Residual risk:** a captive portal that strips DNSSEC and serves
malicious HTTP content. User has to actually click into it; the OS
itself does not auto-trust.

---

### A3 — Malicious or compromised application

**Scenario:** user installs a Flatpak that turns out to be hostile,
or a previously-trusted app is hijacked upstream.

**Capabilities:** runs as the user, but inside whatever sandbox we
provide. Tries to read `~/.ssh`, `~/.config`, KWallet, browser
profiles, exfiltrate over the network.

**Goal:** persistence, credential theft, data exfiltration.

**Controls:**

- Flatpak deny-by-default: revoked filesystem=host/home, devices=all,
  session/system bus, cups/pcsc/gpg-agent/ssh-auth sockets, network
  shared, devel/multiarch features. LD_PRELOAD stripped.
- Flathub remote filtered to verified publishers by default — most
  users never see unverified apps without opting in.
- Portal-mediated access (xdg-desktop-portal-kde): camera, mic,
  screencast, file open all go through user-visible prompts.
- Per-app overrides require explicit `flatpak override` (or M6 KCM
  panel) — there is no implicit "trust all" affordance.

**Residual risk:** a verified-publisher app that ships with broad
permissions the user grants because the dialog asks. Mitigated by
shipping a M6 KCM that visualises every grant and lets the user
revoke per-app post-hoc.

---

### A4 — Local privilege escalation from a sandboxed process

**Scenario:** the attacker has code execution as the user (A3
succeeded enough to land an exploit) and now tries to become root.

**Controls:**

- SELinux enforcing + targeted policy.
- `kernel.unprivileged_userfaultfd=0` and
  `kernel.unprivileged_bpf_disabled=1` close the two most common
  current LPE primitives.
- `kernel.kexec_load_disabled=1` prevents loading an unverified
  kernel even if root is briefly gained.
- `kernel.yama.ptrace_scope=1` blocks cross-process injection.
- `fs.protected_*` blocks classic /tmp race exploits.
- `vm.mmap_min_addr=65536` blocks NULL-deref-as-LPE.
- `kernel.kptr_restrict=2` and `dmesg_restrict=1` slow KASLR
  bypass.
- All Orion-shipped daemons run with landlock + seccomp policies.

**Residual risk:** zero-day kernel bugs. We cannot defend against
those; we can only minimise their blast radius.

---

### A5 — Prompt-injection attack on AI subsystem

**Scenario:** user pastes content (web page, email, document) into
Orion Copilot. Content contains hidden instructions trying to make
the AI exfiltrate clipboard, send mail, delete files, or call cloud
APIs the user did not authorise.

**Capabilities:** can craft arbitrary text reaching the model.

**Goal:** unauthorised destructive action; credential / data
exfiltration; cloud spend abuse.

**Controls (full implementation in M4–M6):**

- Bubblewrap-isolated `orion-aid` process. No host filesystem, no
  network unless the routing mode permits it.
- Air-Gapped mode is firewall-enforced, not policy-enforced. Air-gap
  leak test in CI is a release blocker.
- Every destructive action (file delete/move, NL Launcher command,
  outbound API call) requires an explicit user confirmation dialog.
  Prompt-injection reaches the dialog, not the action.
- Hard cloud spend cap. Tested by `tests/integration/test_spend_cap.py`
  (plan §5.5). Even a successful injection cannot drain the user's
  API balance.
- KWallet master-password gate on cloud key access — the daemon
  cannot fish keys out of memory across reboots.

**Residual risk:** social-engineering of a confirmation dialog. We
mitigate by making destructive prompts visually distinct (red border,
"AI-initiated action" label) and by adding a 1-second cooldown
before the confirm button enables.

---

### A6 — Supply-chain compromise

**Scenario:** an upstream we depend on (Aurora, Fedora, a Cargo crate,
a container action) is compromised and ships a malicious update.

**Controls:**

- Pinned base image (`aurora-dx:41`).
- Cosign signature on every Orion image, verified by users at install.
- SBOM (SPDX + CycloneDX) attested with `cosign attest` for every
  release. Users can list every component.
- Trivy CVE scan in CI (HIGH or CRITICAL fails build) on every image
  and weekly against the same image (catches CVEs published after
  build).
- Reproducible builds: same commit → same image hash, verified in CI.
- Dependabot enabled for GitHub Actions; security updates auto-merge
  via the same review-gated path as anything else.
- All Cargo crates pinned with checksums in `Cargo.lock`.

**Residual risk:** a compromise of GitHub Actions itself, or of
cosign / sigstore. Out of scope; we depend on those root trusts.

---

### A7 — Surveillance / mass-data-collection adversary

**Scenario:** advertising network, commercial data broker, or hostile
state actor wants to fingerprint Orion users at scale.

**Capabilities:** can observe outbound traffic patterns; cannot break
TLS.

**Goal:** identify Orion users, build profiles.

**Controls:**

- **Zero telemetry, ever.** No metrics endpoint, no opt-in toggle,
  no anonymous error reports. Marketing pillar; technical commitment.
- DNS-over-TLS with diverse upstreams reduces single-point traffic
  analysis.
- All update traffic is signed and goes to the same GHCR endpoint
  every Aurora-derived distro hits — Orion users do not stand out.
- M4 air-gap mode for users who genuinely need zero outbound.

**Residual risk:** the user's own browsing / app usage. Not Orion's
problem to solve in the OS layer; we ship Firefox + privacy defaults
and stop there.

---

## 2. Out of scope (and why)

| Threat | Why out of scope |
|---|---|
| Nation-state physical-access attacker with rubber-hose cryptanalysis | If they can compel the passphrase, no software helps. We document this honestly rather than promise the impossible. |
| Hardware implants (e.g. malicious firmware shipped from factory) | Detectable via measured-boot reports; remediation requires hardware swap. The OS cannot heal a compromised root of trust. |
| Side-channel attacks on shared hardware (Spectre family, RowHammer) | Mitigated by the kernel, not by us. We ship the latest stable kernel and inherit upstream mitigations. |
| Cryptographic break of AES / argon2id / ed25519 | If these break, every modern OS has the same problem. We pin to current best practice and update in step. |

---

## 3. Review cadence

- **Every release:** revisit this document and confirm each adversary
  still maps to landed controls.
- **Every new feature with a network or filesystem boundary:**
  add a row to the affected adversary or open a new ADR.
- **Every Lynis or Trivy finding:** triage against the adversary table
  to decide priority.

---

## 4. References

- Plan §5.1 — frozen stack
- Plan §5.4 — AI routing modes (A2 / A5)
- Plan §5.5 — release-blocking quality gates
- Plan §7.5 — security rules
- [`security-model.md`](./security-model.md) — controls in detail
