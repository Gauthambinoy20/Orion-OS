# syntax=docker/dockerfile:1.7

# Orion OS — Containerfile (M1, P#1.3)
#
# This file exists for two reasons:
#
#   1. **Local hacking.** Contributors who do not want to install the
#      full BlueBuild CLI can still build a runnable Orion image with
#      a single `podman build .` (or `docker build .`), which is the
#      lowest-friction path for first-time contributors.
#
#   2. **Fallback CI path.** If the BlueBuild action ever breaks
#      upstream, our build-image workflow can fall back to building
#      this Containerfile directly. BlueBuild internally generates an
#      equivalent Containerfile from the recipe; this is the same shape,
#      just hand-written.
#
# The canonical, officially-supported build path is still
# `bluebuild build image/recipe.yml` and the GitHub Actions workflow
# (P#1.4). Keep the two in sync: when a recipe gains a real layer,
# mirror it here. CI verifies both paths produce a bootable image
# (smoke test in P#1.10).
#
# References:
#   - Plan §5.1 (Aurora base, image-based)
#   - image/recipe.yml — source of truth for the assembled image

# -----------------------------------------------------------------------------
# Stage 1: pull the upstream Aurora image, pinned the same way the
# BlueBuild recipe pins it. Bump in lockstep with image/recipe.yml.
# -----------------------------------------------------------------------------
ARG AURORA_TAG=41
FROM ghcr.io/ublue-os/aurora-dx:${AURORA_TAG} AS base

# -----------------------------------------------------------------------------
# Stage 2: identity. Mirrors image/recipes/base.yml step 1 (files).
# These overwrite the Aurora-shipped identity files so the resulting
# image self-identifies as Orion in /etc/os-release and to any tool
# that reads os-release metadata.
# -----------------------------------------------------------------------------
COPY image/files/etc/os-release       /etc/os-release
COPY image/files/etc/orion-release    /etc/orion-release

# -----------------------------------------------------------------------------
# Stage 3: package layer. Mirrors image/recipes/base.yml step 2 and
# image/recipes/kde.yml step 1. We use rpm-ostree inside the image so
# the result remains a valid OSTree commit that bootc / rpm-ostree can
# rebase onto, the same way BlueBuild does it.
#
# Kept in a single RUN to minimise layers; packages here MUST stay in
# sync with the recipes. CI fails the build if they drift (P#1.10).
# -----------------------------------------------------------------------------
RUN rpm-ostree install \
        git just jq ripgrep fd-find age \
        plasma-desktop plasma-workspace plasma-systemmonitor \
        kwin kde-cli-tools \
        dolphin konsole kate kcalc gwenview okular ark \
        spectacle partitionmanager \
 && rpm-ostree override remove \
        kmail akregator korganizer kontact \
        kmahjongg kpat kmines \
 && ostree container commit

# -----------------------------------------------------------------------------
# Labels. OCI standard plus a couple of Orion-specific markers used by
# our update / rollback tooling (M2). Image version is filled in by CI;
# locally it stays "dev".
# -----------------------------------------------------------------------------
ARG ORION_VERSION=dev
LABEL org.opencontainers.image.title="Orion OS" \
      org.opencontainers.image.description="AI-first KDE desktop on Aurora" \
      org.opencontainers.image.source="https://github.com/gauthambinoy/Orion-OS" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      org.opencontainers.image.version="${ORION_VERSION}" \
      io.orionos.base="aurora-dx:${AURORA_TAG}" \
      io.orionos.recipe="image/recipe.yml"
