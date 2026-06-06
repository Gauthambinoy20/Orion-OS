<!--
Thanks for opening a PR. Please fill out every section below.

Reviewers will close PRs that:
- Disable or weaken a CI gate (plan §7.6)
- Bundle multiple purposes into one commit (plan §6.1)
- Add a feature that is not on the 12-hero list and not behind an ADR (plan §5.2)
- Lack tests for the new behaviour (plan §7.4)
-->

## Push reference

<!-- Reference the push number from ORION_DEVELOPMENT_PLAN.md §6.3, e.g. P#1.4 -->
**P#**:

Linked issue (if any): #

## Summary

<!-- One paragraph: what does this PR do, and why? Explain the why. -->

## Type of change

- [ ] `feat` — new user-visible functionality
- [ ] `fix` — bug fix
- [ ] `perf` — performance improvement
- [ ] `refactor` — code change that neither fixes a bug nor adds a feature
- [ ] `docs` — documentation only
- [ ] `ci` / `build` — pipeline or build system
- [ ] `chore` — repo housekeeping
- [ ] `security` — security-relevant change (also fill the Security section)
- [ ] Other: ____

## Architecture impact

- [ ] No impact on §5 (architecture), §5.2 (hero features), or §5.5 (gates)
- [ ] Impacts the above — **ADR PR is linked**: #

## Tests

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] E2E smoke test added/updated
- [ ] Performance test added/updated (if a perf-budgeted path is touched)
- [ ] Air-gap test added (if this PR adds an AI feature, per plan §7.4)
- [ ] N/A — explain: ____

## Quality gates

- [ ] All CI checks pass locally where reproducible
- [ ] No CI gate was disabled or weakened
- [ ] No new dependency added without an ADR (plan §7.6)
- [ ] No `unsafe` Rust outside `audited-unsafe.toml`
- [ ] No secrets, telemetry, or unaudited cloud calls added

## Security

<!-- Required if you ticked `security` above, or if this PR touches:
     orion-aid, the router, KWallet usage, sandboxing, signing, the
     installer, or any cloud provider plugin. -->

- Threat-model impact:
- New trust assumptions introduced:
- How was this change reviewed for security regressions?

## Screenshots / recordings

<!-- For any UI change, attach a screenshot or short recording. For shell
     output, paste a fenced code block. -->

## Checklist

- [ ] Commit subject ≤ 72 chars and follows Conventional Commits
- [ ] Commit body explains *why*, not *what*
- [ ] Docs updated in this same PR (if behaviour or interfaces changed)
- [ ] I read CONTRIBUTING.md and the relevant section of the master plan
