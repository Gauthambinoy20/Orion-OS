# Orion OS — Master Development Plan

> **Status:** Living document. Single source of truth.
> **Owner:** @gauthambinoy
> **Last revised:** 2026-04-18
> **Audience:** Human maintainers and contributors.

---

## 0. How to read this document

This file is the **constitution** of Orion OS. Every decision, every commit, every quality gate is here. If something isn't here, it isn't approved.

- Sections **1–4** are strategy (the "why").
- Section **5** is the architecture (the "what").
- Section **6** is the **commit-by-commit execution plan** (the "how").
- Section **7** is the **engineering rules & contribution workflow**.
- Section **8** is the growth & launch strategy (the "boom").
- Section **9** is the appendix (decisions, alternatives considered, glossary).

**Update rule:** When a milestone tag is cut, the maintainer updates the "Last revised" date and the milestone status table in §6.

---

## 1. Vision (one paragraph)

Orion OS is an **AI-first, image-based Linux desktop** that is faster, more secure, and more useful out of the box than Windows or macOS — without selling a single byte of user data. Every Orion install ships with a local AI brain that can see your screen, understand your voice, search your files by meaning, and drive your apps — all working offline by default, with optional hybrid cloud routing for heavy tasks. Orion is to "AI desktops" what Tesla was to cars in 2012: not the first, but the first that's actually good.

## 2. Anti-vision (what Orion is NOT)

- ❌ Not a vanilla Linux distro with ChatGPT pre-installed
- ❌ Not a custom kernel or custom DE we maintain from scratch
- ❌ Not telemetry-funded
- ❌ Not "100x better than Windows in 1 month with 200M users" (impossible — see §9.1)
- ❌ Not feature-bloat: 12 hero features done excellently > 200 features done badly
- ❌ Not closed source. GPL-3.0-or-later, period.

## 3. Target users (in priority order)

1. **Privacy-conscious power users** (devs, sysadmins, journalists, researchers) — the same people who run Fedora Atomic, Bazzite, NixOS today. They are our beachhead.
2. **AI-curious creators** (writers, designers, students) who want local AI without learning Ollama/Python.
3. **"I'm tired of Windows" switchers** who tried Linux once, bounced because of friction. Year-2 audience.

## 4. Strategic pillars (what makes us different)

| Pillar | What it means | Why it wins |
|---|---|---|
| **AI native, not AI bolted-on** | Every part of the desktop has AI hooks: launcher, clipboard, terminal, file manager, search, photos, voice. | No competitor does this end-to-end. |
| **Local-first, hybrid optional** | Default: 100% offline AI. User explicitly opts into cloud per-feature with hard spend caps. | Privacy as a *provable* default, not a marketing line. |
| **Atomic + signed + rollback** | OCI image base (Universal Blue), cosign-signed, `rpm-ostree rollback` one click. | An update can never brick your machine. |
| **Hardware-tier aware** | OS detects your tier (low/mid/high/pro) and ships the right model + tuning automatically. | Works on a 2018 laptop AND a 2025 RTX desktop. |
| **Beautiful by default** | KDE Plasma 6 with curated themes, layouts, and fonts. macOS-grade polish out of the box. | Linux's #1 historical weakness, fixed. |
| **Verifiable claims** | Every privacy/perf/security promise is enforced by a CI test. No marketing without a test. | Trust is the only moat. |

---

## 5. Technical architecture

### 5.1 Stack (frozen — do not change without an ADR)

| Layer | Choice | Why (vs alternatives) |
|---|---|---|
| Base OS | **Fedora Atomic via Universal Blue Aurora** | Atomic, OTA, rollback, KDE-first, 1M+ user proven. (Alternatives: NixOS = too steep learning curve; OpenSUSE MicroOS = smaller community.) |
| Build system | **BlueBuild → OCI → GHCR** | Declarative recipes, free CI, signed by default. (Alt: mkosi = lower level, more work.) |
| Desktop | **KDE Plasma 6** + optional Hyprland session | Modern, customizable, Wayland-native, Kirigami QML for our shells. (Alt: GNOME = less customizable; ours is a customization-first OS.) |
| Kernel | **CachyOS kernel (BORE scheduler)** | Best-in-class desktop responsiveness benchmarks. (Alt: Liquorix, XanMod — CachyOS has the most active dev.) |
| Init | systemd (inherited) | No reason to change. |
| Memory | **zram** (compressed swap) + **ananicy-cpp** | Real perf on low-RAM machines. |
| Power | power-profiles-daemon + custom orion-tune | Battery + perf tuning per tier. |
| Sandboxing | **Flatpak** (apps) + **bubblewrap** (AI features) + **landlock + seccomp** (daemons) | Defense in depth. |
| Security baseline | SELinux enforcing, LUKS2 + TPM2 (passphrase fallback **mandatory**), firewalld strict, DNS-over-HTTPS, signed boot path | Industry best practice. |
| Languages | **Rust** (all daemons/CLI/services) + **QML/Kirigami** (all UI) | Two languages only. Faster onboarding, fewer bugs. |
| AI runtime | **orion-aid** (Rust daemon) wrapping Ollama + llama.cpp + whisper.cpp + Piper + LLaVA + Real-ESRGAN + rembg + Tesseract | Standard, proven, locally hosted. |
| Vector store | **sqlite-vec + age encryption** | Simpler than LanceDB, easier to audit, single file. |
| Cloud routers (opt-in) | OpenRouter, Anthropic, OpenAI, Groq, Together, LAN Ollama | User-supplied keys, stored in KWallet. |
| Installer | Calamares (KDE-native) | Battle-tested. |
| Updates | rpm-ostree + staged channel rollout | Atomic, rollback-able. |
| Telemetry | **None. Zero. Ever.** | Marketing pillar. |

### 5.2 The 12 hero features (v1.0 scope — locked)

Anything not on this list is **post-v1.0**. No exceptions. Plugin marketplace handles the rest.

1. **Orion Copilot** — KDE sidebar. Streaming chat with screen/app context. Encrypted history.
2. **NL Launcher** — `Super+Space` → natural-language → command/app/action. Always confirms before destructive ops.
3. **Screen Sense** — `Super+Shift+A` → describe / OCR / Q&A any region.
4. **Voice Control** — "Hey Orion" wake-word (opt-in, off by default). STT + TTS pipeline. Always-on indicator.
5. **AI Clipboard** — Klipper extension. Explain / translate / rewrite / summarize.
6. **AI Terminal** — Konsole plugin. NL→cmd, error explain, command history search by intent.
7. **Semantic File Search** — Background indexer (idle-only). Search files by meaning, not just name.
8. **Personal RAG** — Chat with your opt-in folders. Per-folder grant/revoke.
9. **Photo Super-Actions** — Dolphin right-click: bg-remove, upscale, describe, OCR.
10. **Translate Overlay** — `Super+T` → live region/text translation.
11. **Meeting Capture** — System+mic audio → offline transcript + summary + action items.
12. **Smart Focus & Power** — DND triage, notification ranking, learned power-profile switching.

### 5.3 Tier matrix (what model each user gets by default)

| Tier | RAM | GPU | Default text model | Vision | Voice STT |
|---|---|---|---|---|---|
| **Low** | 8 GB | iGPU | Qwen2.5 3B Q4 | none | whisper.cpp tiny |
| **Mid** | 16 GB | 4–6 GB VRAM | Llama 3.1 8B Q4 | LLaVA 7B | whisper base |
| **High** | 32 GB | 8–12 GB VRAM | Qwen2.5 14B Q4 | LLaVA 13B | whisper small |
| **Pro** | 64 GB+ | 16 GB+ VRAM | Llama 3.3 70B Q4 | Llama 3.2 Vision 11B | whisper medium |

Detected by `orion-tune` at first boot. User can override.

### 5.4 The four AI routing modes (user picks one in first-boot wizard, switchable anytime)

| Mode | Behaviour | Default for |
|---|---|---|
| **Air-Gapped** | 100% local. Network blocked at firewall for orion-aid. CI-verified zero egress. | Journalists, security researchers |
| **Privacy First** | Local first; cloud only for tasks the local model explicitly fails. | **Default for new users.** |
| **Smart Hybrid** | Cost+latency+quality optimizer routes per request. | Power users with API keys |
| **Best Quality** | Always cloud (best available model). | Pro users who don't care about cost |

### 5.5 Non-negotiable quality gates (CI-enforced; release blockers)

A release **cannot ship** if any of these fail:

| Gate | Threshold | Tool |
|---|---|---|
| Boot time (low tier) | ≤ 8 s | `systemd-analyze` in QEMU |
| Boot time (high tier) | ≤ 5 s | self-hosted runner |
| Idle RAM (low tier) | ≤ 1.4 GB | `smem` in QEMU |
| Lynis hardening score | ≥ 90 | Lynis in CI |
| Air-gap leak test | 0 packets out when in Air-Gapped mode | nftables counter in QEMU |
| Voice round-trip latency | < 1.5 s | `tests/perf/voice_latency.py` |
| Cosign signature | All artifacts signed and verified | cosign in CI |
| SBOM | Generated for every image | syft in CI |
| Reproducible build | Same commit → same image hash | rebuild check in CI |
| Hero feature E2E | All 12 pass smoke test in QEMU + real HW runner | `tests/e2e/` |
| Hard spend cap | Cloud spend cap enforced; cannot exceed user limit | `tests/integration/test_spend_cap.py` |
| Unsafe Rust | Zero `unsafe` outside explicitly-audited modules | `cargo-geiger` |

---

## 6. Execution plan (commit by commit)

### 6.1 Workflow rules

- **M0** (this milestone): direct commits to `main` allowed (repo is empty).
- **M1 onward**: every change is a PR from `feature/<milestone>-<short-name>`, squash-merged, signed commit, signed tag.
- **One commit = one purpose.** Never bundle "add X and fix Y".
- **Conventional Commits** mandatory. Subject ≤ 72 chars. Body explains *why*, not *what*.
- Push numbering: `P#<milestone>.<n>` — referenced in commit body for traceability.
- **No commit without a passing CI run.**

### 6.2 Milestone status

| Milestone | Pushes | Tag | Status |
|---|---|---|---|
| M0 — Repo bootstrap | 8 | v0.0.1 | 🟡 in progress |
| M1 — First bootable image | 10 | v0.1.0-alpha | ⬜ pending |
| M2 — Security baseline | 9 | v0.2.0-alpha | ⬜ pending |
| M3 — Performance & tier | 7 | v0.3.0-alpha | ⬜ pending |
| M4 — AI runtime core | 10 | v0.4.0-beta | ⬜ pending |
| M5 — Hero features 1/4 | 9 | v0.5.0-beta | ⬜ pending |
| M6 — Hero features 2/4 | 8 | v0.6.0-beta | ⬜ pending |
| M7 — Hero features 3/4 | 8 | v0.7.0-beta | ⬜ pending |
| M8 — Hero features 4/4 | 5 | v0.8.0-rc1 | ⬜ pending |
| M9 — Onboarding & polish | 10 | v0.9.0-rc2 | ⬜ pending |
| M10 — Public 1.0 launch | 8 | v1.0.0 | ⬜ pending |

**Total: 92 commits, 11 tags.** Realistic timeline: **14–16 months solo**, 9–11 with one co-maintainer. Do not pretend it's faster.

### 6.3 Commit-by-commit ledger

> Update the **status** column as each commit lands. Use ⬜ pending, 🟡 in-progress, ✅ done, ❌ blocked.

#### M0 — Repo Bootstrap (no PR; direct to main)

| # | Commit subject | Files | Status |
|---|---|---|---|
| P#0.1 | `chore: initial commit` | `LICENSE` (GPL-3.0-or-later), `README.md` | ⬜ |
| P#0.2 | `docs: add CONTRIBUTING and CODE_OF_CONDUCT` | `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` | ⬜ |
| P#0.3 | `docs: add SECURITY policy` | `SECURITY.md` | ⬜ |
| P#0.4 | `chore: add gitignore, gitattributes, editorconfig` | `.gitignore`, `.gitattributes`, `.editorconfig` | ⬜ |
| P#0.5 | `ci: add lint workflow (yamllint, shellcheck, gitleaks, commitlint)` | `.github/workflows/lint.yml` | ⬜ |
| P#0.6 | `chore: add issue and PR templates` | `.github/ISSUE_TEMPLATE/*`, `PULL_REQUEST_TEMPLATE.md` | ⬜ |
| P#0.7 | `chore: add CODEOWNERS and dependabot` | `.github/CODEOWNERS`, `.github/dependabot.yml` | ⬜ |
| P#0.8 | `chore: add cosign public key` | `cosign.pub` | ⬜ |

**After M0:** tag `v0.0.1`, enable branch protection, all future work via PR.

#### M1 — First Bootable Image

| # | Commit | Files | Status |
|---|---|---|---|
| P#1.1 | `build: add BlueBuild recipe skeleton` | `image/recipe.yml`, `image/recipes/base.yml` | ⬜ |
| P#1.2 | `build: add KDE Plasma module` | `image/recipes/kde.yml` | ⬜ |
| P#1.3 | `build: add Containerfile` | `Containerfile` | ⬜ |
| P#1.4 | `ci: add image build workflow` | `.github/workflows/build-image.yml` | ⬜ |
| P#1.5 | `ci: add ISO build workflow` | `.github/workflows/build-iso.yml`, `iso/isogenerator.yml` | ⬜ |
| P#1.6 | `chore: add justfile with dev tasks` | `justfile` | ⬜ |
| P#1.7 | `scripts: local QEMU test runner` | `scripts/dev/test-vm.sh` | ⬜ |
| P#1.8 | `branding: placeholder logo and wallpaper` | `branding/logo/`, `branding/wallpapers/` | ⬜ |
| P#1.9 | `docs: developer setup guide` | `docs/dev-guide/setup.md` | ⬜ |
| P#1.10 | `ci: add VM smoke test` | `.github/workflows/test-vm.yml`, `tests/smoke/01-boots.sh` | ⬜ |

**Tag:** `v0.1.0-alpha`. Verify: ISO boots in QEMU, KDE login works.

#### M2 — Security Baseline

| # | Commit | Files | Status |
|---|---|---|---|
| P#2.1 | `security: enable cosign image signing in CI` | `.github/workflows/sign-release.yml` | ⬜ |
| P#2.2 | `security: SELinux enforcing config` | `image/files/etc/selinux/config` | ⬜ |
| P#2.3 | `security: hardened sysctls` | `image/files/etc/sysctl.d/99-orion-hardening.conf` | ⬜ |
| P#2.4 | `security: firewalld strict default` | `image/files/etc/firewalld/zones/orion.xml` | ⬜ |
| P#2.5 | `security: DNS-over-HTTPS via systemd-resolved` | `image/files/etc/systemd/resolved.conf.d/orion-doh.conf` | ⬜ |
| P#2.6 | `installer: LUKS2 + TPM2 default in Calamares (passphrase fallback mandatory)` | `iso/calamares/` | ⬜ |
| P#2.7 | `security: Flatpak restrictive defaults` | `image/files/etc/flatpak/`, override script | ⬜ |
| P#2.8 | `ci: add security scan workflow (Trivy + Lynis)` | `.github/workflows/security-scan.yml` | ⬜ |
| P#2.9 | `docs: security model and threat model` | `docs/security-model.md`, `docs/threat-model.md` | ⬜ |

**Tag:** `v0.2.0-alpha`.

#### M3 — Performance & Tier

| # | Commit | Files | Status |
|---|---|---|---|
| P#3.1 | `perf: layer CachyOS kernel` | `image/recipes/performance.yml` | ⬜ |
| P#3.2 | `perf: enable zram swap` | `image/files/etc/systemd/zram-generator.conf` | ⬜ |
| P#3.3 | `perf: ananicy-cpp + preload` | recipe additions | ⬜ |
| P#3.4 | `feat(orion-tune): hardware tier detection` | `crates/orion-tune/` | ⬜ |
| P#3.5 | `perf: power-profiles-daemon + laptop tuning` | files + systemd unit | ⬜ |
| P#3.6 | `ci: enforce boot time and RAM budgets` | extends `test-vm.yml` | ⬜ |
| P#3.7 | `docs: performance budgets` | `docs/dev-guide/performance.md` | ⬜ |

**Tag:** `v0.3.0-alpha`.

#### M4 — AI Runtime Core

| # | Commit | Files | Status |
|---|---|---|---|
| P#4.1 | `chore: init Rust workspace` | `Cargo.toml`, `rust-toolchain.toml`, `crates/orion-common/` | ⬜ |
| P#4.2 | `feat(orion-aid): daemon skeleton` | `crates/orion-aid/` | ⬜ |
| P#4.3 | `feat(orion-aid): Ollama backend` | runtime client | ⬜ |
| P#4.4 | `feat(orion-aid): cloud backends (OpenRouter, Anthropic, OpenAI, Groq)` | provider modules + config | ⬜ |
| P#4.5 | `feat(orion-aid): smart routing engine (4 modes)` | router | ⬜ |
| P#4.6 | `feat(orion-aid): D-Bus API + KWallet secret store` | API surface | ⬜ |
| P#4.7 | `build: bake Ollama + whisper.cpp + Piper into image` | `image/recipes/ai.yml` | ⬜ |
| P#4.8 | `feat(orion-ai-setup): first-boot model installer` | `scripts/orion-ai-setup` | ⬜ |
| P#4.9 | `feat(orion-cli): orion command (chat, fix, explain)` | `crates/orion-cli/` | ⬜ |
| P#4.10 | `test: integration tests for AI routing + spend cap` | `tests/integration/` | ⬜ |

**Tag:** `v0.4.0-beta` ⭐ **first beta — first usable AI release**.

#### M5 — Hero Features Batch 1 (Copilot, NL Launcher, Screen Sense)

| # | Commit | Status |
|---|---|---|
| P#5.1 | `feat(copilot): KDE Kirigami sidebar shell` | ⬜ |
| P#5.2 | `feat(copilot): backend wired to orion-aid (streaming)` | ⬜ |
| P#5.3 | `feat(copilot): context awareness (active app, selection)` | ⬜ |
| P#5.4 | `feat(copilot): encrypted conversation history (sqlite+age)` | ⬜ |
| P#5.5 | `feat(krunner-ai): natural-language plugin` | ⬜ |
| P#5.6 | `feat(krunner-ai): explain-then-run safety flow` | ⬜ |
| P#5.7 | `feat(orion-vision): screen capture daemon (Super+Shift+A)` | ⬜ |
| P#5.8 | `feat(orion-vision): vision model integration (LLaVA)` | ⬜ |
| P#5.9 | `test: smoke tests for 3 hero features` | ⬜ |

**Tag:** `v0.5.0-beta`.

#### M6 — Hero Features Batch 2 (Voice, Clipboard, Terminal)

| # | Commit | Status |
|---|---|---|
| P#6.1 | `feat(voice): wake-word daemon (OpenWakeWord, opt-in, off by default)` | ⬜ |
| P#6.2 | `feat(voice): STT (whisper.cpp) + TTS (Piper) pipeline` | ⬜ |
| P#6.3 | `feat(voice): command intent + safety confirm` | ⬜ |
| P#6.4 | `feat(voice): KDE indicator + permission flow` | ⬜ |
| P#6.5 | `feat(clipboard): Klipper extension with AI actions` | ⬜ |
| P#6.6 | `feat(clipboard): encrypted history (sqlite+age)` | ⬜ |
| P#6.7 | `feat(terminal-ai): Konsole plugin` | ⬜ |
| P#6.8 | `test: voice latency benchmark in CI (<1.5s)` | ⬜ |

**Tag:** `v0.6.0-beta`.

#### M7 — Hero Features Batch 3 (Search, RAG, Photo)

| # | Commit | Status |
|---|---|---|
| P#7.1 | `feat(search): background indexer service (idle-only)` | ⬜ |
| P#7.2 | `feat(search): sqlite-vec encrypted vector store` | ⬜ |
| P#7.3 | `feat(search): KRunner backend for semantic queries` | ⬜ |
| P#7.4 | `feat(rag): per-folder opt-in scoping + revoke` | ⬜ |
| P#7.5 | `feat(rag): chat-with-files in copilot` | ⬜ |
| P#7.6 | `feat(photo): Dolphin actions (bg-remove, upscale, describe, OCR)` | ⬜ |
| P#7.7 | `feat(photo): Real-ESRGAN + rembg + Tesseract integration` | ⬜ |
| P#7.8 | `test: integration tests for search + RAG + photo` | ⬜ |

**Tag:** `v0.7.0-beta`.

#### M8 — Hero Features Batch 4 (Translate, Meeting, Focus)

| # | Commit | Status |
|---|---|---|
| P#8.1 | `feat(translate): Super+T region/text translate overlay` | ⬜ |
| P#8.2 | `feat(meeting): system audio + mic capture (Pipewire)` | ⬜ |
| P#8.3 | `feat(meeting): offline transcript + summary + action items` | ⬜ |
| P#8.4 | `feat(focus): smart DND + notification triage` | ⬜ |
| P#8.5 | `feat(focus): power profile learning (extends orion-tune)` | ⬜ |

**Tag:** `v0.8.0-rc1`. **All 12 hero features complete.**

#### M9 — Onboarding, Customization, Polish

| # | Commit | Status |
|---|---|---|
| P#9.1 | `feat(firstboot): QML wizard skeleton` | ⬜ |
| P#9.2 | `feat(firstboot): AI mode selection + cloud key setup` | ⬜ |
| P#9.3 | `feat(orion-center): settings hub (QML/Kirigami)` | ⬜ |
| P#9.4 | `feat(orion-center): theme + layout preset switcher` | ⬜ |
| P#9.5 | `feat(orion-center): per-feature AI toggles + spend caps UI` | ⬜ |
| P#9.6 | `feat: 5 polished themes (Light, Dark, Catppuccin, Tokyo Night, Nord)` | ⬜ |
| P#9.7 | `feat: 4 layout presets (KDE / macOS / Win11 / Tiling-Hyprland)` | ⬜ |
| P#9.8 | `branding: final logo, wallpapers, plymouth, sddm, sounds` | ⬜ |
| P#9.9 | `installer: Calamares branding + 5-screen flow` | ⬜ |
| P#9.10 | `docs: complete user guide and FAQ` | ⬜ |

**Tag:** `v0.9.0-rc2`.

#### M10 — Public 1.0 Launch

| # | Commit | Status |
|---|---|---|
| P#10.1 | `release: cut release/v1.0 branch` | ⬜ |
| P#10.2 | `docs: complete CHANGELOG.md` | ⬜ |
| P#10.3 | `web: project website (Astro + Cloudflare Pages)` | ⬜ |
| P#10.4 | `docs: deploy mkdocs site to Cloudflare Pages` | ⬜ |
| P#10.5 | `ci: release signing pipeline (cosign + syft SBOM)` | ⬜ |
| P#10.6 | `release: v1.0.0` | ⬜ |
| P#10.7 | `docs: post-launch announcement` | ⬜ |
| P#10.8 | `ops: enable update channels (unstable/testing/stable)` | ⬜ |

**Tag:** `v1.0.0` 🚀 **SHIP**.

---

## 7. Engineering rules & contribution workflow

> **Read this before any change.** These rules apply to every contribution to
> this repo, whether written by hand or with automated assistance.

### 7.1 Working model & permission rules

- Work on **one push (P#X.Y) at a time**. Never bundle.
- Read this file first, locate the next pending commit in §6.3, and only execute that one.
- **Never** invent new commits, milestones, or features. Anything new requires an ADR (see §9.3).
- **Never push to `main` after M0.** Only via PR from `feature/<milestone>-<slug>` branches.
- **Never** disable a CI gate to "make it pass". If a gate fails, fix the code, not the gate.

### 7.2 Mandatory pre-flight checks (every session)

Before writing any code:

1. `git status` — confirm clean working tree.
2. `git pull --ff-only origin main` — sync.
3. Open this file, find the next ⬜ pending commit.
4. Verify all dependencies (previous commits) are ✅.
5. Read the relevant subsection of §5 (architecture).
6. Read the security model (`docs/security-model.md`) if the change touches security.
7. Confirm this is the right next step before starting.

### 7.3 Style & structure rules

| Rule | Enforcement |
|---|---|
| Rust 2024 edition, `clippy::pedantic` clean | CI |
| No `unsafe` outside modules whitelisted in `audited-unsafe.toml` | `cargo-geiger` in CI |
| `rustfmt` default config | CI |
| QML files pass `qmllint` | CI |
| Shell scripts pass `shellcheck -S error` | CI |
| YAML passes `yamllint` strict | CI |
| Markdown passes `markdownlint` (loose: line length off) | CI |
| Conventional Commits subject ≤ 72 chars | commitlint |
| Every public Rust fn has `///` doc | `clippy::missing_docs_in_private_items` warn |
| Every D-Bus interface has a versioned XML schema in `interfaces/` | manual review |

### 7.4 Testing rules

- Every new feature ships with **at least one** test in the appropriate level:
  - Unit (`cargo test` per crate)
  - Integration (`tests/integration/`)
  - E2E smoke (`tests/smoke/`)
  - Performance (`tests/perf/` — if it touches the perf-budget-enforced paths)
- Every new AI feature ships with an **air-gap test** that verifies it works (or fails gracefully) in Air-Gapped mode.
- Every new feature with a UI ships with a **screenshot test** (PNG diff against golden) — KDE provides `kwin-screenshot`.

### 7.5 Security rules (non-negotiable)

- **No secrets in code.** Ever. Use KWallet at runtime, GitHub Secrets in CI.
- **No outbound network calls** in any daemon unless explicitly routed through `orion-aid`'s router (which respects the user's mode).
- **No `wget | sh`** in any script. Always download, verify checksum, then run.
- **No background telemetry.** Even crash reports must be opt-in and locally previewable before submission.
- **All cloud provider plugins** must support a `dry-run` mode that prints what they *would* send.
- **All AI prompts** sent to cloud providers must be logged to `~/.local/share/orion/cloud-audit.log` (user-readable, auto-rotated, encrypted at rest with user key).

### 7.6 Prohibited changes

- ❌ Add a new dependency (Rust crate, npm package, Flatpak, RPM) without an ADR.
- ❌ Change a quality gate threshold.
- ❌ Disable a CI step.
- ❌ Rewrite history (force-push, rebase shared branches).
- ❌ Modify `cosign.pub`, `SECURITY.md`, `LICENSE`, `CODEOWNERS`, or this plan file without explicit maintainer approval in the PR.
- ❌ Add telemetry of any kind.
- ❌ Add a "small feature" that isn't on the 12-hero list (post-1.0 only).
- ❌ Speed up by skipping tests.
- ❌ Commit binary blobs > 1 MB (use Git LFS or external artifact storage).

### 7.7 When stuck

If a commit cannot be completed in 3 attempts:

1. Stop.
2. Document the blocker in the PR description with: error output, what was tried, hypothesis.
3. Mark the commit ❌ blocked in §6.3.
4. Open an issue with label `blocker`.
5. Wait for input. Do not improvise.

---

## 8. Growth & launch strategy (the "boom")

> **The honest truth:** No new desktop OS gets 200M users in a month. Set yourself up for the long game and you might genuinely get 100k–1M users in 2–3 years, which is *huge* for a desktop Linux distro. Below is the realistic playbook.

### 8.1 Audience-building (start at P#0.1, not v1.0)

| Channel | What to post | Cadence |
|---|---|---|
| **Devlog blog** (Astro on Cloudflare Pages) | Per-commit micro-posts; weekly long-form deep dive | Weekly |
| **Mastodon** | Build screenshots, polls, milestone announcements | 3×/week |
| **Bluesky** | Same as Mastodon, slightly more polished | 3×/week |
| **Lemmy `/c/linux`** | Major milestones only, no spam | Per tag |
| **YouTube channel "Building Orion OS"** | 5-min build-log per milestone; demo videos for hero features | Per tag |
| **Reddit `r/orion_os`** (own subreddit) | Devlogs cross-posted, community Q&A | Weekly |
| **Reddit `r/linux`, `r/unixporn`, `r/linuxquestions`** | Major milestones only | Per tag |
| **Hacker News** | One Show HN at v0.4 (first beta), one at v1.0 | 2 total |
| **Discord server** | Open at M1 (not M10). Channels: announcements, general, help, dev | Live |
| **Newsletter** (Buttondown) | Monthly summary | Monthly |

**Goal: 1,000 newsletter subs and 5,000 devlog readers BEFORE v1.0 ships.** They are your day-1 user base.

### 8.2 The "killer demo" doctrine

Build the entire v1.0 launch around **ONE 60-second video** that makes the audience *feel* the product. Suggested:

> *Press `Super+Space` → say "summarize the PDF I was just reading and draft an email to mom about it" → 3 seconds later, draft is open in KMail. Network unplugged. All offline.*

Every hero feature must be cuttable into a 15-second standalone video for social. Schedule a video per feature in the 4 weeks leading up to v1.0.

### 8.3 Funding model (decide at M0, not v1.0)

| Source | What | When |
|---|---|---|
| **GitHub Sponsors** | Individual donors $5–$50/mo | P#0.1 |
| **Open Collective** | Transparent finances for grants/companies | M1 |
| **NLnet / Sovereign Tech Fund grants** | €30k–€100k for privacy/security infra | Apply at M4 (working alpha) |
| **Orion Pro** ($5/mo) | Managed cloud AI credits + priority builds + private Discord | Post v1.0 |
| **Hardware partnerships** | Framework, System76, Tuxedo — preinstall deal, revenue share | Post v1.0, after 5k users |
| **Enterprise support contracts** | $$$ for orgs deploying >50 seats | v1.5+ |

**Burn target solo:** ~$1.5k/mo (cloud build, domains, hosting, modest stipend). Cover this with Sponsors+OC by month 6 or stop.

### 8.4 The 12-month launch calendar

| Month | Public milestone | Audience target |
|---|---|---|
| 1 | M0 done; devlog live; "I'm building this" post | 100 readers |
| 3 | M3 done; first boot video | 500 |
| 6 | M4 done = `v0.4.0-beta` first usable AI; Show HN #1 | 5,000; 200 alpha testers |
| 9 | M6 done; voice demo viral attempt | 15,000; 1,000 beta testers |
| 12 | M9 done; RC; press kit to LinuxUnplugged, TechHut, DistroTube, Brodie Robertson | 30,000 |
| 14 | **v1.0 launch.** Show HN #2. ProductHunt. Coverage from at least 3 Linux YouTubers. | **5k–50k installs in first month**, growing to **100k–500k year 1** if quality holds |

### 8.5 Outside-the-box plays (high-risk, high-upside)

These are gambles. Only run them after v1.0 is solid.

1. **"Orion Pro" pre-installed on a partner laptop** — Framework or Tuxedo branded SKU. Revenue share funds the project.
2. **"Bring your own model" marketplace** — community uploads model + tuning recipes; signed and rated. Becomes a moat.
3. **Education edition** — free for schools/universities, with curriculum. Tap into next-gen mindshare. Linux Mint did this poorly; we do it well.
4. **AI-driven distro auto-tune** — Orion ships a "tune my system" wizard that uses local AI to read benchmarks and apply tuning. No other distro does this.
5. **Live OS in a USB sold on Amazon for $19** — for the non-technical "AI-curious" crowd that won't flash an ISO. Margins fund growth.
6. **Public "transparency dashboard"** — live page showing: # cloud calls made by users (aggregated, opt-in), avg spend, % air-gapped users, recent CVE response time. **Trust as marketing.**
7. **Tie a hero feature to a known frustration** — "the OS that finds files you forgot the name of" beats "AI desktop" every time. Pick one specific pain and own it.

### 8.6 What 100/100 looks like at v1.0

- v1.0 ships on time (≤ 16 months from P#0.1).
- All 12 quality gates green at release.
- 5,000+ Discord members; 30,000+ devlog readers; 1,000+ Pro subscribers within 90 days post-launch.
- Coverage in: HN front page, LWN, Phoronix, TechHut, Brodie Robertson, DistroTube, The New Stack.
- One major hardware partner LOI signed.
- One NLnet or STF grant approved.
- Self-sustaining revenue ≥ $5k/mo by month 18.

---

## 9. Appendix

### 9.1 Why "200M users in 1 month" is impossible (honest math)

- ChatGPT (fastest-growing consumer app ever) took ~2 months to hit 100M MAU — and it's an *app*, not an OS.
- Windows took ~40 years to hit 1B users; Android ~10 to hit 1B; Ubuntu ~15 to hit ~50M.
- An OS requires: driver compatibility (years of work), app ecosystem (decades), user trust (forever), distribution channels (none for indie OSes), and hardware partnerships (slow).
- A realistic best-case for a brilliantly-executed niche AI Linux distro is **100k–1M users in years 2–3**. Bazzite (closest comparable) is at ~100k after ~2 years.
- Setting unrealistic targets causes burnout, panic-shipping bad releases, and reputation damage. **Set the long-game target and over-deliver instead.**

### 9.2 Alternatives considered (and rejected)

| Considered | Rejected because |
|---|---|
| Building from scratch (own kernel/init) | 1000× more work; no practical benefit. |
| Arch base | Less stable for non-power-users; harder OTA story. |
| NixOS base | Steep learning curve for end users *and* contributors. |
| GNOME desktop | Less customizable; Orion's pillar is customization. |
| LanceDB | More dependencies than sqlite-vec; harder to audit. |
| Tauri/Svelte UIs | Adds a 3rd language; Kirigami covers our needs. |
| Telemetry (even opt-in) | Reputation cost > engineering benefit. Document in `SECURITY.md`. |

### 9.3 ADR (Architecture Decision Record) process

For any change to §5 (architecture), §5.5 (gates), or §5.2 (hero features):

1. Open a PR adding `docs/adr/NNNN-<slug>.md`.
2. Template: Context / Decision / Alternatives / Consequences / Status.
3. Requires 1 maintainer approval (post-v1.0: 2).
4. If accepted, this plan file is updated in the same PR.

### 9.4 Glossary

- **OCI image**: Container image format (Docker/Podman compatible). Universal Blue ships the OS as one.
- **rpm-ostree**: Atomic package layering on Fedora Atomic. Each "deployment" is a snapshot.
- **BlueBuild**: Declarative tool to compose Universal Blue OCI images via YAML recipes.
- **Cosign**: Sigstore tool for signing/verifying OCI artifacts.
- **SBOM**: Software Bill of Materials. Generated by `syft`. Required for supply-chain transparency.
- **Air-gap**: No network egress allowed. Verified by nftables packet counter.
- **Tier**: Hardware class (low/mid/high/pro) detected by `orion-tune`.

### 9.5 Contact & ownership

- Maintainer: @gauthambinoy
- Security reports: see `SECURITY.md`
- Code of Conduct: see `CODE_OF_CONDUCT.md`

---

**End of plan. Total length: this is the full constitution. If you change anything substantive, bump the "Last revised" date at the top.**
