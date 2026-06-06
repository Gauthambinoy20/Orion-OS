# Orion OS — Roadmap

This is the at-a-glance progress tracker. The authoritative, commit-by-commit
plan lives in [`ORION_DEVELOPMENT_PLAN.md`](ORION_DEVELOPMENT_PLAN.md) §6 — this
file summarises it and records where the repository actually is today.

**Current phase:** pre-alpha, pipeline green. The image **builds, is
cosign-signed, and is published to GHCR**; the **ISO builds and its checksum is
signed**; and all six CI workflows are green. No release **tag** has been cut
yet — the full booted-VM smoke and the `v0.1.0-alpha` tag are the remaining M1
exit criteria (they need a KVM runner; see Known issues).

## How to use this

Per-step loop: plan → write the smallest slice → write its test → run → tick the
box and its test ids → commit → review. Priority tags: **(core)** must-have ·
**(polish)** do if time · **(stretch)** only after core + polish are green. The
commit-by-commit authority is [`ORION_DEVELOPMENT_PLAN.md`](ORION_DEVELOPMENT_PLAN.md) §6.

## Milestones

Legend: `[x]` complete · `[~]` scaffolded, not yet validated by a release tag ·
`[ ]` not started.

| | Milestone | Tag | Status |
|---|---|---|---|
| `[x]` | **M0 — Repo bootstrap** | `v0.0.1` | Licence, governance docs, lint CI, templates, cosign key — all committed |
| `[~]` | **M1 — First bootable image** | `v0.1.0-alpha` | Image builds + signs + publishes to GHCR; ISO builds + signs; qcow2 conversion validated. Tag pending full booted-VM smoke on a KVM runner |
| `[~]` | **M2 — Security baseline** | `v0.2.0-alpha` | SELinux, sysctls, firewalld, DoH, Flatpak lockdown, LUKS2 + TPM2 installer, Trivy + Lynis scan — committed |
| `[ ]` | **M3 — Performance & tier** | `v0.3.0-alpha` | CachyOS kernel, zram, `orion-tune` tier detection |
| `[ ]` | **M4 — AI runtime core** | `v0.4.0-beta` | `orion-aid` daemon, local + cloud backends, routing, spend caps |
| `[ ]` | **M5 — Hero features 1/4** | `v0.5.0-beta` | Copilot, NL Launcher, Screen Sense |
| `[ ]` | **M6 — Hero features 2/4** | `v0.6.0-beta` | Voice, Clipboard, Terminal |
| `[ ]` | **M7 — Hero features 3/4** | `v0.7.0-beta` | Search, RAG, Photo |
| `[ ]` | **M8 — Hero features 4/4** | `v0.8.0-rc1` | Translate, Meeting, Focus |
| `[ ]` | **M9 — Onboarding & polish** | `v0.9.0-rc2` | First-boot wizard, settings hub, themes |
| `[ ]` | **M10 — Public 1.0 launch** | `v1.0.0` | Website, docs site, release pipeline |

**Progress to v1.0:** ~1 of 11 milestones complete (M0); M1–M2 scaffolded.
Total planned scope is **92 commits / 11 tags**; realistic timeline **14–16
months solo** (do not pretend it is faster — see plan §8.1).

## M0 — Repo bootstrap (delivered)

- [x] GPL-3.0-or-later licence
- [x] README, master development plan, CONTRIBUTING, code of conduct, security policy
- [x] Editorconfig, gitignore, gitattributes, lint configs (yamllint, markdownlint, commitlint)
- [x] Lint workflow (yamllint, shellcheck, markdownlint, commitlint, gitleaks)
- [x] Issue + PR templates, CODEOWNERS, Dependabot, cosign public key

## Known issues

- **Image CVE scan is report-only.** The HIGH/CRITICAL findings are in the
  upstream Fedora / Universal Blue base we rebase onto, not in packages this
  repo pins, so they are fixed upstream and arrive on the weekly base rebuild.
  Findings are uploaded to the Security tab; CVEs in our own files are still
  enforced by the `trivy-config` job.
- **Lynis hardening gate (plan §5.5)** is *report-only* in `security-scan`.
  Lynis audits a running system, so a non-booted container audit structurally
  under-scores; the `>= 90` release-blocker enforcement belongs in the booted
  VM and should move there when full-boot CI is available.
- **`test-vm` full boot needs KVM.** On hosted runners (no `/dev/kvm`) it
  validates that the image converts to a bootable qcow2, then stops green. The
  full emulated boot + SSH + smoke (and the stock image's lack of a
  preconfigured login) runs on a KVM-capable self-hosted runner.
- No tagged ISO release or boot screenshots yet — they follow the first
  release tag and a KVM boot run.

## Test Inventory

Numbered so coverage is provable, not just a number. Repository-integrity
checks run in CI (the `validate-repo` lint job, `just test-repo`); boot smoke
runs in the VM on a KVM runner.

- [x] T01 — os-release VERSION_ID equals the recipe base-image major  (`validate-repo`)
- [x] T02 — os-release is comment-free KEY=VALUE  (`validate-repo`)
- [x] T03 — every files-module `source:` exists under `files/`  (`validate-repo`)
- [x] T04 — every recipe `from-file:` target exists under `recipes/`  (`validate-repo`)
- [x] T05 — all YAML passes strict yamllint  (`lint`)
- [x] T06 — all shell passes `shellcheck -S error`  (`lint`)
- [x] T07 — all Markdown passes markdownlint  (`lint`)
- [x] T08 — no secrets in history (gitleaks)  (`lint`)
- [x] T09 — image builds and is cosign-signed  (`build-image`)
- [x] T10 — installable ISO builds and its checksum is signed  (`build-iso`)
- [x] T11 — image converts to a bootable qcow2  (`test-vm`, no-KVM path)
- [x] T12 — CodeQL analysis of workflows + JS  (`codeql`)
- [ ] T13 — booted-VM smoke: services up, base tools present, removed apps absent  (`test-vm`, KVM) · _(stretch — needs KVM runner)_

## Feature catalogue

| Area | Priority | Status |
|---|---|---|
| BlueBuild image (base + KDE) | core | ✅ builds, signed, on GHCR |
| Security baseline (SELinux/firewalld/sysctl/DoH/Flatpak) | core | ✅ baked into image |
| LUKS2 + TPM2 installer (Calamares) | core | ✅ config shipped |
| Installable ISO + signed checksum | core | ✅ builds in CI |
| Supply chain: cosign signing, SBOM, Trivy, CodeQL | core | ✅ green (image CVE report-only) |
| Booted-VM smoke gate | polish | ⏳ KVM runner |
| Performance & tier (M3) · AI runtime (M4) · 12 hero features (M5–M8) | stretch | ⬜ planned |

## Known issues (continued)

- **Maximum test surface is thin by nature.** This repo is declarative
  (YAML/shell/config), so coverage is integrity + lint + the booted smoke, not
  unit tests. Logic-bearing code (the Rust daemons, M4+) ships with unit tests.

## Next

1. Stand up a KVM-capable runner to enforce the booted-VM smoke (T13) and the
   Lynis `>= 90` gate, then cut **`v0.1.0-alpha`** (M1 done).
2. Begin **M3** (performance & tier): CachyOS kernel, zram, `orion-tune`.

## Definition of Done (whole project)

Mirrors the 10/10 gate: single-author trace-clean history · builds + runs with
proof · maximum warranted tests green · zero fake data · full CI green with real
badges · supply-chain signed (cosign + SBOM) · no unactionable CVEs in our code
· small human commits · README + ROADMAP + diagrams complete · pushed. Adapted
for an OS image: "deploy" is the signed GHCR image + ISO (not a web/AWS app), so
the AWS/Terraform and web-UI/Lighthouse gates are N/A by project type.

## ✍️ TODO: my words

<!-- Personal notes on priorities / what I'm focusing on next — mine to fill. -->
