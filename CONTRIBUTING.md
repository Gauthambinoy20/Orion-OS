# Contributing to Orion OS

Thank you for considering a contribution. Orion OS is a focused project with
a strict, public plan. Please read this whole file before opening an issue
or PR.

## Read the plan first

The [Master Development Plan](ORION_DEVELOPMENT_PLAN.md) is the constitution
of this project. Every architectural decision, quality gate, and milestone
is recorded there. If something is not in the plan, it is not approved.

In particular, before you start work, read:

- **§5 — Architecture** (the stack is frozen; changes require an ADR — §9.3)
- **§5.2 — The 12 hero features** (anything outside this list is post-1.0)
- **§5.5 — Quality gates** (release-blocking; do not weaken them)
- **§6 — Execution plan** (find the next pending push and only execute that one)
- **§7 — Engineering rules & contribution workflow**

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By
participating you agree to abide by it. Report unacceptable behaviour to
the maintainer (see `CODE_OF_CONDUCT.md` for the contact address).

## How to propose a change

1. **Check the plan.** Find the next ⬜ pending push in §6.3 of the plan,
   or open an issue to discuss anything that is not on the ledger.
2. **Open an issue first** for any non-trivial change. Describe the problem,
   the proposed approach, and any alternatives considered.
3. **For architecture-level changes** (anything affecting §5, §5.2, or §5.5):
   open an ADR PR adding `docs/adr/NNNN-<slug>.md` using the template in
   §9.3 of the plan. The ADR must be merged *before* the implementation PR.

## Branching and commits

- After milestone M0, **all changes ship as a PR** from a feature branch:
  `feature/<milestone>-<short-name>` (e.g. `feature/m1-bluebuild-recipe`).
- Squash-merge only.
- Sign your commits and tags. The cosign public key lives in `cosign.pub`.
- **Conventional Commits are mandatory.** Subject ≤ 72 characters.
- The commit body explains *why*, not *what*. Reference the push number
  (e.g. `P#1.4`) and any related issue.

## One commit, one purpose

Never bundle "add X and fix Y". Split the work. The reviewer should be able
to understand each commit in isolation.

## Tests

Every new feature ships with at least one test in the appropriate level
(unit / integration / E2E smoke / performance). See §7.4 of the plan.

A PR will not merge until:

- All CI gates are green
- The change is covered by tests where applicable
- The relevant docs are updated in the same PR

**Do not disable a CI gate to make it pass.** Fix the code instead.

## Style

- Rust 2024, `clippy::pedantic` clean, `rustfmt` default
- QML must pass `qmllint`
- Shell scripts must pass `shellcheck -S error`
- YAML must pass `yamllint` (strict config)
- Markdown must pass `markdownlint` (line-length disabled)

The `lint` workflow enforces all of the above.

## Security

If you believe you have found a security vulnerability, **do not open a
public issue.** Follow the disclosure process in [`SECURITY.md`](SECURITY.md).

## Licensing of contributions

By submitting a contribution you agree that it is licensed under the
project licence ([GPL-3.0-or-later](LICENSE)). Do not submit code that
is not yours to relicense.

## Thank you

Orion OS is a long-game project. Every well-scoped issue, every focused PR,
every reproducible bug report makes the difference between a v1.0 that
ships and one that does not. We appreciate your time.
