Looks like `gh` isn't authenticated — run `gh auth login` and I'll pick this up.

I need `gh` to pull PR #847's metadata, diff, and commits from `integralads/report-data-processor`. WebFetch can't read the repo (it's private), and falling back to your current local branch would be wrong — the local branch may not match what's on the PR, and silently swapping targets is worse than no answer.

Once you've authenticated, ping me and I'll write the description.
