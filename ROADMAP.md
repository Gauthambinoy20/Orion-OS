# Orion OS — Roadmap

This is the at-a-glance progress tracker. The authoritative, commit-by-commit
plan lives in [`ORION_DEVELOPMENT_PLAN.md`](ORION_DEVELOPMENT_PLAN.md) §6 — this
file summarises it and records where the repository actually is today.

**Current phase:** pre-alpha. The repository, the build/sign/ISO pipeline, and
the security baseline are in place. No release tag has been cut yet.

## Milestones

Legend: `[x]` complete · `[~]` scaffolded, not yet validated by a release tag ·
`[ ]` not started.

| | Milestone | Tag | Status |
|---|---|---|---|
| `[x]` | **M0 — Repo bootstrap** | `v0.0.1` | Licence, governance docs, lint CI, templates, cosign key — all committed |
| `[~]` | **M1 — First bootable image** | `v0.1.0-alpha` | BlueBuild recipes, Containerfile, image/ISO/VM workflows present; image build is being driven green in CI |
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

- The image has **not** been built into a published, signed artifact yet — the
  `build-image` workflow is being driven green; release signing activates once
  the `COSIGN_PRIVATE_KEY` secret is configured.
- No installable ISO or screenshots yet (both follow the first green image build).

## Next

1. Get `build-image` green and publish the first `orion` image to GHCR.
2. Configure the cosign signing secret so published images are signed.
3. Cut `v0.1.0-alpha` once the ISO boots in QEMU (M1 exit criteria).

## ✍️ TODO: my words

<!-- Personal notes on priorities / what I'm focusing on next — mine to fill. -->
