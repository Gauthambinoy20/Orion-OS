// Orion OS — commitlint configuration
//
// Conventional Commits, mandatory per ORION_DEVELOPMENT_PLAN.md §6.1 and §7.3.
// Subject ≤ 72 chars. Type list reflects the kinds of commits the plan
// actually uses (chore, docs, ci, build, feat, fix, perf, refactor, test,
// security, branding, scripts, installer, release, ops, web).

module.exports = {
    extends: ["@commitlint/config-conventional"],
    rules: {
        "header-max-length": [2, "always", 72],
        "body-leading-blank": [2, "always"],
        "footer-leading-blank": [2, "always"],
        "subject-case": [
            2,
            "never",
            ["sentence-case", "start-case", "pascal-case", "upper-case"],
        ],
        "type-enum": [
            2,
            "always",
            [
                "build",
                "branding",
                "chore",
                "ci",
                "docs",
                "feat",
                "fix",
                "installer",
                "ops",
                "perf",
                "refactor",
                "release",
                "revert",
                "scripts",
                "security",
                "style",
                "test",
                "web",
            ],
        ],
    },
};
