# Orion OS — developer setup guide

This guide gets a fresh contributor from a clean Linux/macOS shell to
*"I just built and booted Orion in a VM"* in well under an hour. If a
step here is wrong or out of date, that is a bug — please open a PR.

## Who this is for

Anyone who wants to build, modify, or test Orion OS. No Linux distro
or kernel experience required; you should be comfortable with `git`
and a terminal.

## Required tools

| Tool | Version | Why |
|---|---|---|
| `git` | any recent | source control |
| `just` | 1.x+ | task runner ([install](https://github.com/casey/just#installation)) |
| `podman` *or* `docker` | recent | container runtime for image build |
| `qemu-system-x86_64` + KVM | any recent | local VM smoke test |
| `cosign` | v2.x | verifying release artefacts ([install](https://docs.sigstore.dev/system_config/installation)) |
| `bluebuild` (CLI) | latest | canonical image build (optional; the Containerfile path works without it) |

### One-liner installs

**Fedora / Aurora / RHEL family:**

```bash
sudo dnf install -y git just podman qemu-kvm
# cosign + bluebuild from upstream (see links above)
```

**Debian / Ubuntu:**

```bash
sudo apt install -y git podman qemu-system-x86 qemu-kvm
# 'just' from cargo or the upstream installer:
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
```

**macOS (Homebrew):**

```bash
brew install git just podman qemu cosign
```

After installing the tools, run:

```bash
just doctor
```

This prints every tool's version. If anything is missing, the recipe
tells you exactly what.

## Cloning

```bash
git clone https://github.com/gauthambinoy/Orion-OS.git
cd Orion-OS
```

You probably want SSH for push access; HTTPS is fine for read-only.

## The four things you need to know

1. **The plan is the constitution.** Read [`ORION_DEVELOPMENT_PLAN.md`](../../ORION_DEVELOPMENT_PLAN.md)
   first, especially §6 (commit ledger) and §7 (engineering rules). That file
   is owned and may not be edited by contributors except via an ADR PR.
2. **One PR per logical change.** Squash-merge to `main`. PR titles
   follow Conventional Commits (`type(scope): subject` ≤ 72 chars). The
   `commitlint` job in CI is the source of truth.
3. **Lint locally before pushing** with `just lint` — same checks CI
   runs, no surprises.
4. **Image and ISO builds are heavy.** Don't run them on every PR.
   They run automatically on `main` and on tagged releases.

## Building locally

### Option A: BlueBuild CLI (canonical)

```bash
just build-image                # ORION_TAG=dev by default
ORION_TAG=mytest just build-image
```

This produces `localhost/orion:dev`.

### Option B: Containerfile (no BlueBuild required)

```bash
just build-container
# or with docker:
CONTAINER=docker just build-container
```

Same result, simpler tooling. Used as the CI fallback.

## Booting in QEMU

```bash
just test-vm                    # interactive: prints the SSH command
# in another terminal:
ssh -p 2222 orion@localhost
```

To run smoke tests headless and tear the VM down at the end:

```bash
scripts/dev/test-vm.sh --smoke orion:dev
```

KVM is auto-detected; on hosts without `/dev/kvm` (some CI runners,
some Macs) the script falls back to TCG. Slower, but it works.

## Verifying release artefacts

Every release ships with a cosign-signed checksum:

```bash
sha256sum -c orion-<tag>.iso.sha256
cosign verify-blob \
  --key cosign.pub \
  --signature orion-<tag>.iso.sha256.sig \
  orion-<tag>.iso.sha256
```

`cosign.pub` lives in the repo root. The matching private key is held
by the maintainer and stored only as the `COSIGN_PRIVATE_KEY` GitHub
Actions secret — see [`SECURITY.md`](../../SECURITY.md) for the trust
model.

## Where to find things

| Path | What lives there |
|---|---|
| `recipes/recipe.yml` | top-level BlueBuild recipe (entry point) |
| `recipes/*.yml` | per-concern recipes (base, KDE, …) |
| `files/etc/` | files copied verbatim into the image |
| `Containerfile` | fallback build path (must mirror the recipes) |
| `iso/isogenerator.yml` | ISO build configuration |
| `.github/workflows/` | CI (lint, build-image, build-iso, smoke) |
| `branding/` | logo + wallpaper assets (placeholders until M8) |
| `scripts/dev/` | local-only developer scripts |
| `tests/smoke/` | scripts the test-vm runner executes inside the VM |
| `docs/adr/` | architecture decision records |
| `cosign.pub` | trust root: signature verification key |

## Getting help

- **Bug?** Open an issue using the bug-report template.
- **Idea or feature?** Open a discussion before opening a PR for
  anything bigger than a one-file change.
- **Security issue?** See [`SECURITY.md`](../../SECURITY.md). Do **not**
  open a public issue.

Welcome to Orion. Happy hacking.
