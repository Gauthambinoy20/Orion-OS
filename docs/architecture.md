# Orion OS — Architecture

This document describes how Orion OS is assembled, derived directly from the
recipes under [`recipes/`](../recipes) and [`files/`](../files), the ISO config under [`iso/`](../iso), and
the workflows under [`.github/workflows/`](../.github/workflows). Every node
below maps to a real file in the repository.

For the rationale behind these choices, see the
[Master Development Plan](../ORION_DEVELOPMENT_PLAN.md) §5 (technical
architecture).

## 1. Component architecture

How the image is composed, from upstream base to signed artifacts.

```mermaid
flowchart TD
    subgraph upstream["Upstream"]
        aurora["ghcr.io/ublue-os/aurora-dx:43<br/>Fedora Atomic + KDE Plasma 6"]
    end

    subgraph recipe["BlueBuild recipe (recipes/)"]
        entry["recipe.yml<br/>(entry point / base-image pin)"]
        base["recipes/base.yml"]
        kde["recipes/kde.yml"]
        sec["recipes/security.yml"]
        files["files/etc/* + files/usr/libexec/orion/*<br/>(SELinux, sysctls, firewalld,<br/>DoH, Flatpak, release identity)"]
    end

    cfile["Containerfile<br/>(fallback build path)"]

    subgraph artifacts["Signed artifacts"]
        oci["OCI image<br/>ghcr.io/&lt;owner&gt;/orion"]
        iso["Installable ISO<br/>(iso/isogenerator.yml)"]
    end

    installer["Calamares installer<br/>(iso/calamares/*)<br/>LUKS2 + TPM2"]
    disk[("Encrypted user disk")]

    aurora --> entry
    entry --> base --> kde --> sec
    sec --> files
    files --> oci
    cfile -.fallback.-> oci
    oci --> iso
    iso --> installer
    installer --> disk
    oci -. cosign sign .-> oci
```

## 2. Data flow (DFD)

How declarative sources become an installed, encrypted system.

```mermaid
flowchart LR
    src1["Recipe YAML<br/>(recipes/recipe.yml,<br/>recipes/*.yml)"]
    src2["Baked config + scripts<br/>(files/*)"]
    src3["Branding assets<br/>(branding/*)"]

    build(["BlueBuild build<br/>(CI: build-image.yml)"])
    sign(["cosign sign<br/>+ syft SBOM"])
    ghcr[("GHCR<br/>OCI registry")]
    isogen(["isogenerator<br/>(CI: build-iso.yml)"])
    isoart["ISO artifact"]
    calamares(["Calamares install"])
    disk[("LUKS2-encrypted disk<br/>TPM2-enrolled")]

    src1 --> build
    src2 --> build
    src3 --> build
    build --> sign --> ghcr
    ghcr --> isogen --> isoart
    isoart --> calamares --> disk
```

## 3. Build, sign & verify sequence

The lifecycle of a change, from push to a signed, verifiable release.

```mermaid
sequenceDiagram
    actor Dev as Maintainer
    participant GH as GitHub Actions
    participant BB as BlueBuild
    participant REG as GHCR
    participant COS as cosign / syft
    participant QEMU as QEMU (test-vm)

    Dev->>GH: push / open PR
    GH->>GH: lint.yml (yaml, shell, md, commit, gitleaks)
    alt pull request
        GH->>BB: build image (no push)
        Note over GH: surfaces recipe breakage early
    else push to main / tag
        GH->>BB: build image
        BB->>REG: push ghcr.io/<owner>/orion
        GH->>COS: cosign sign (by digest)
        GH->>QEMU: boot ISO, run tests/smoke
    end
    opt on release tag (v*)
        GH->>COS: re-tag, SBOM attest
        GH->>Dev: GitHub Release (signature + SBOM + cosign.pub)
    end
```

## 4. Release & distribution topology

How a build reaches a user's machine — Orion's equivalent of a deployment
diagram. There is no app server: the "deploy" is a signed image in a registry
plus an ISO.

```mermaid
flowchart TD
    subgraph ci["GitHub Actions (CI/CD)"]
        bi["build-image"]
        iso["build-iso"]
        rel["sign-release (tags)"]
    end
    ghcr[("GHCR<br/>ghcr.io/gauthambinoy20/orion<br/>:latest · :43 · :&lt;sha&gt;-43")]
    sig["cosign signatures<br/>(.sig tags)"]
    sbom["SBOM (syft)"]
    relpage["GitHub Release<br/>(ISO + .sha256 + .sig)"]

    bi --> ghcr
    bi --> sig
    iso --> relpage
    rel --> sbom
    rel --> relpage

    ghcr -->|rpm-ostree rebase| dev1["existing Fedora Atomic user"]
    relpage -->|flash + Calamares install| dev2["new install (LUKS2 + TPM2)"]
    sig -.cosign verify --key cosign.pub.-> dev1
```

## 5. Security & trust boundaries

Where untrusted input enters and what is trusted. Caption: everything left of a
boundary is untrusted until verified at it.

```mermaid
flowchart LR
    subgraph untrusted["Untrusted"]
        net["Network / mirrors"]
        upstream["Upstream base image<br/>(ublue-os/aurora-dx)"]
        contrib["PR from a fork"]
    end

    subgraph trust["Trust boundary: CI"]
        verify["cosign verify base + lint + Trivy/CodeQL"]
        keys["Signing key<br/>(COSIGN_PRIVATE_KEY secret,<br/>never in fork PRs)"]
    end

    subgraph trusted["Trusted, signed artifacts"]
        img["Signed OCI image"]
        isoart["ISO + signed checksum"]
    end

    user["User verifies with cosign.pub"]

    upstream --> verify
    net --> verify
    contrib -->|build only, no push, no key| verify
    verify --> keys --> img --> isoart
    img --> user
    isoart --> user
```
