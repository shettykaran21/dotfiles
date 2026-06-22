No `pull_request_template.md` in this repo, so I used the default template. Here's the filled-in description:

```markdown
## Summary

- Align column headers with metrics in `config.json` so the report's displayed header order matches the metric output.
- Adds `totalEligible` count and `failed` pct columns alongside the existing `viewable` / `blocked` columns.

## Testing

- [ ] Verified report renders with headers in the expected order on a sample dataset.
- [ ] Existing tests still pass.

## Ticket

[PORT-1783](https://integralads.atlassian.net/browse/PORT-1783)
```

**Note:** `src/main/resources/application.yml` has unstaged changes (looks like a local-dev queue name tweak). Make sure it stays out of this PR before pushing.

No PR was specified, so I've just printed the markdown for you to paste. If you want me to push it directly next time, give me the PR link or number and I'll use `gh pr edit`.
