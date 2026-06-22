---
name: pr-description
description: >
  Write or update a GitHub pull request description using the repo's
  pull_request_template.md. Use this skill whenever the user asks to draft,
  fill in, write, or update a PR description / pull request description,
  whether they pass a PR link, a PR number, or nothing at all (in which case
  use the current git branch). Trigger for phrases like "write a PR
  description", "fill in the PR description", "draft the PR body",
  "update the description on <PR URL>", or "pull request description".
---

# PR description writer

Turn a branch's commits and diff into a focused, reviewer-friendly pull
request description that follows the repo's own template.

The point of a PR description isn't to describe the diff — reviewers can read
code. It's to tell the reviewer *what decision was made and why*, and to let
them scan the scope in a few seconds. Keep that as the north star.

---

## Inputs

The user provides one of:

1. A GitHub PR URL (e.g. `https://github.com/<org>/<repo>/pull/123`)
2. A PR number (if the working directory is already in that repo)
3. Nothing — in which case use the current git branch

---

## Step 1: Source the diff

### If a PR URL or number was given

Use `gh` (the GitHub CLI):

- Check it's installed: `command -v gh`
- Check it's authenticated: `gh auth status`

If gh isn't installed or isn't authenticated, **stop and ask the user to run
`gh auth login`**. Don't try to fetch the PR any other way — WebFetch can't
read private repos, and falling back to the local branch is error-prone
because the local branch may not match the PR.

Then gather:

- PR metadata (title, body, branches): `gh pr view <n> --json number,title,body,headRefName,baseRefName,url`
- The diff: `gh pr diff <n>`
- Commits on the PR: `gh pr view <n> --json commits`

### If nothing was given — use the current branch

Identify the base branch:

- First try the remote default: `git symbolic-ref refs/remotes/origin/HEAD --short` (gives e.g. `origin/master`).
- Fall back to whichever of `master` or `main` exists locally.

Then gather:

- `git log <base>..HEAD --oneline`
- `git diff <base>...HEAD --stat`
- `git diff <base>...HEAD`
- `git status --short` — so you can flag uncommitted files at the end (see "Flag out-of-scope changes").

---

## Step 2: Find the template

Check these paths in order and use the first one that exists:

1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `pull_request_template.md` (repo root)
4. `docs/pull_request_template.md`

If none exist, use this default:

```markdown
## Summary

## Testing

## Ticket
```

**Preserve the template's structure.** Headings, ordering, checkboxes, HTML
comments, and placeholder text are often there because the reviewer or the
team's process expects them (e.g. a "Rollback plan" section, a "Screenshots"
section). Don't drop sections just because you don't have content — leave
them empty, or write `_N/A_`, so the reviewer can see you considered them.

Comments inside the template like `<!-- describe the change -->` are hints
for what belongs in that section — read them and follow them, but don't
include them in the final output.

---

## Step 3: Handle existing descriptions

If the target PR already has a non-empty body, **ask the user before writing**:

> This PR already has a description. Want me to **rewrite** it from scratch, or **merge updates** — keep your wording and only add bullets for new commits since the current body was written?

Wait for their answer.

For the **merge** case: read the existing body, figure out which commits it
likely already covers (by matching ticket IDs, feature keywords, or commit
SHAs referenced in the body), and only add/revise bullets for commits that
aren't represented. Don't reflow prose the user wrote — only extend or edit
the sections where new content belongs.

---

## Step 4: Extract the ticket ID

Pull the first Jira-style ticket ID from the branch name. Regex (case-insensitive):

```
[A-Z][A-Z0-9]+-[0-9]+
```

Branch names often have suffixes — `PORT-1783-v2`, `PORT-1783-update`,
`feat/PORT-1783`, `bugfix/port-1783-fix`. The regex above catches all of
these when applied case-insensitively; always normalize the matched ID to
uppercase in the output.

Link it as:

```markdown
[PORT-1783](https://integralads.atlassian.net/browse/PORT-1783)
```

If no ticket ID is present, leave the Ticket field empty rather than
inventing one.

---

## Step 5: Write the description

### Summary

A good summary answers: *what decision was made, and why does it matter?* A
reviewer who only reads the summary should understand the intent of the PR
without needing to read the diff.

- **2-3 bullets is the target.** More is fine when the PR genuinely spans
  unrelated concerns — but if you're padding to fill space, cut it.
- **Write at the intent level, not the file level.** A bullet like "Updated
  `databricks.yml` and 24 resource YMLs to remove `git_sha`" is worse than
  "`git_sha` removed — it was redundant with `release_version` and was
  causing a mutator conflict." The reviewer can see which files changed;
  they can't see the reasoning.
- **Smell test:** if a bullet could be replaced by reading the diff stat
  output, it's not earning its place. Cut it or rewrite it to say *why*.
- Each bullet should stand alone — avoid "This PR also..." or numbered
  sequences that read like a changelog.

### What to leave out

- File names, line numbers, counts of files changed — the diff shows this.
- Restating the commit message verbatim.
- Step-by-step narration of what the code does — explain the *decision*,
  not the mechanics.
- Filler phrases: "This PR...", "In this change...", "As part of this work..."

### Testing section

If the template has a Testing section (or you're using the default), fill it
with checkboxes (`- [ ]`) so the user can tick them off as they verify.
Base the items on the nature of the change:

- UI change → "verified in browser"
- Config change → "tested in dev / staging"
- Pure refactor → "existing tests still pass"
- Data pipeline / job → "dry-run with sample input"

Keep it short — 1-3 items. A Testing section isn't a test plan, it's a
checklist the author promises to complete.

### Sections you have nothing for

If the template has a section and you genuinely have nothing to say (e.g.
"Screenshots" on a backend-only PR), write `_N/A_` rather than deleting the
heading. The reviewer wants to see that you considered it.

---

## Step 6: Flag out-of-scope changes

If `git status --short` showed uncommitted files in the working tree, add a
short note **outside the PR description block** — this isn't part of the
description, it's a heads-up to the user:

> **Note:** `application.yml` has unstaged changes (local dev config — personal queue name, file import). Make sure they stay out of the PR.

This matters because PRs often accidentally ship local-dev tweaks when the
author copies a description and forgets a dirty working tree. A PR-description
skill that silently ignores the working tree is doing its user a disservice.

---

## Step 7: Deliver the output

1. **Always print the markdown** in a fenced code block so the user can copy
   it. Do this regardless of whether you also push.
2. **If gh is authenticated AND a target PR was given**, offer to push:
   > I can update the PR description directly with `gh pr edit <n> --body-file -`. Want me to?

   Wait for an explicit "yes" before running — pushing to a PR is visible to
   others and reversing it (via the GitHub UI history) is awkward. Pipe the
   description via stdin or a temp file, not `--body "..."`, so special
   characters and newlines don't break.
3. **If gh isn't authenticated** and the user had a specific PR in mind, add
   one line at the end:
   > Run `gh auth login` if you want me to push updates directly next time.

---

## Examples

### Example 1: Simple branch, no PR link

User: "fill the PR description for this branch"

What you do:
- `git symbolic-ref refs/remotes/origin/HEAD --short` → `origin/master`
- `git log master..HEAD --oneline` → one commit: `PORT-1783: Align column headers...`
- `git diff master...HEAD --stat` + full diff
- `git status --short` → `M src/main/resources/application.yml` (unstaged)
- Check `.github/pull_request_template.md` → not present, use default
- Extract `PORT-1783` from branch name
- Print filled-in markdown
- Add the out-of-scope note about `application.yml`

### Example 2: PR URL given, description already exists

User: "update the description on https://github.com/integralads/report-data-processor/pull/847"

What you do:
- `gh auth status` → OK
- `gh pr view 847 --json number,title,body,headRefName,baseRefName` → body is non-empty
- Ask: rewrite or merge?
- On "merge": pull new commits since last body update, add bullets for them
- Print the markdown
- Offer to push via `gh pr edit 847 --body-file -`

### Example 3: gh not authenticated, PR URL given

User: "write the description for https://github.com/integralads/report-data-processor/pull/847"

What you do:
- `gh auth status` → not authenticated
- Stop. Tell the user: "Looks like `gh` isn't authenticated — run `gh auth login` and I'll pick this up."

Don't try to analyze the current local branch instead. The user asked about
a specific PR; a silently-swapped target is worse than no answer.
