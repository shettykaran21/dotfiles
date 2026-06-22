Using the repo's template at `.github/pull_request_template.md`. Here's the filled-in description:

```markdown
## What does this PR do?

- Fixes the `c_lvl` metric calculation in `Metric.java` by threading a `cLvl` flag through `getValue()` and adding the corresponding getter/setter.
- Adds a test scaffold (`MetricTest.java`) for follow-up unit tests.

## Why is this change needed?

[DDL-2026](https://integralads.atlassian.net/browse/DDL-2026) — the previous implementation returned raw values regardless of conversion-level context, which produced incorrect results for `c_lvl`-gated metrics.

## How was this tested?

- [ ] Unit tests pass
- [ ] Manually verified

## Rollback plan

Revert the two commits on `feat/DDL-2026-fix-c-lvl-metrics`. The change is isolated to `Metric` — no schema or downstream consumers affected.

## Screenshots (if UI change)

_N/A_ — backend change.
```

No PR link was given, so I just printed the markdown. Pass me a PR URL / number next time if you'd like me to push the update via `gh pr edit`.
