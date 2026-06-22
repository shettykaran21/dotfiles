## General Behaviour

- **Step-by-step edits**: Make changes incrementally, one logical step at a time. Never make large sweeping edits in a single turn — the goal is that each change is small enough to review and understand before moving on.
- **No silent fallbacks**: If an operation fails or context is missing, ask for clarification. Don't hallucinate a fix or implement a broken workaround.
- **Formatting**: Match the existing codebase style exactly — indentation, spacing, typing conventions. Don't reformat code that isn't being changed.

## Tools & Environment

- **Shell**: zsh
- **Editor**: neovim — use `nvim`, never `vim` or `nano`
- **Terminal**: WezTerm + tmux
- **Clipboard**: use `pbcopy`/`pbpaste` for clipboard operations

---

## Context Management

- **Progressive disclosure**: Don't load everything upfront. Start with what's immediately needed. If deeper context is required, refer to the project's `README.md` or `docs/` folder before asking the user.

---

## MySQL MCP (firewall DB)

When the user asks you to query the `mcp_server_mysql` MySQL MCP server for the first time in a session, fetch the Firewall DB Data Dictionary for context (do not re-fetch on subsequent queries in the same session):
- **Main page**: https://jira-integralads.atlassian.net/wiki/spaces/EN/pages/12556158/Firewall+DB+Data+Dictionary
- This page has sub-pages for each table — also fetch the relevant sub-page when working with a specific table, but only if you haven't already fetched it this session.

Use this to understand table structure, column semantics, and relationships before writing or explaining queries.
