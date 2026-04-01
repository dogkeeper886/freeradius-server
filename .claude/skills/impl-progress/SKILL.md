---
name: impl-progress
description: Track implementation progress for a FreeRADIUS contribution against the project's contribution guidelines. Use after picking an issue to work on.
argument-hint: "[issue-number]"
allowed-tools: Bash(gh *), Bash(git *), Bash(make *), Read, Grep, Glob
---

## FreeRADIUS Contribution Progress Tracker

Track and verify each step required by the FreeRADIUS contribution guidelines when implementing a fix or feature.

### Input

- `$ARGUMENTS` — the issue number being worked on

### Steps

For the given issue, check the current state of the working tree, branches, commits, and tests to determine which steps are done and which remain.

#### Step 1: Gather current state

Run these in parallel:

```bash
git branch --show-current
```

```bash
git log --oneline -5
```

```bash
git diff --stat HEAD
```

```bash
git status --short
```

#### Step 2: Check each requirement

| # | Step | How to Check |
|---|------|-------------|
| 1 | **Verify bug on Git HEAD of correct branch** | Is the current branch `v3.2.x`, `master`, or a branch based on one of them? Was the bug reproduced? Check git log for evidence. |
| 2 | **Check ChangeLog for existing fix** | `grep` for issue number or keywords in `doc/ChangeLog` on the target branch. |
| 3 | **Not targeting EOL branch** | Current branch must not be `v3.0.x` or older. |
| 4 | **Assess scope** | Count changed lines: `git diff --stat`. Small (1-10 lines) = can PR directly. Large = needed dev team contact first. |
| 5 | **Read coding standards** | Cannot verify automatically. Mark as TODO and remind user. |
| 6 | **Build the server** | Check if `build/bin/local/radiusd` or `build/bin/radiusd` exists and is newer than source changes. |
| 7 | **Reproduce the bug** | Check if a test file exists that demonstrates the bug. Look in `src/tests/` for files related to the issue. |
| 8 | **Write the fix** | Check `git diff` for actual code changes (not just tests). |
| 9 | **Include test case** | Check `git diff --stat` or `git status` for new/modified test files under `src/tests/`. |
| 10 | **Run existing tests** | Cannot verify automatically. Mark as TODO and remind user to run `make tests.unit`. |
| 11 | **Commit on correct branch** | Check `git log` for a commit referencing the issue number. |
| 12 | **Format PR description** | Not applicable until PR is opened. Remind: triple backticks for logs, escape `#<num>`. |
| 13 | **Open PR** | Check: `gh pr list --repo FreeRADIUS/freeradius-server --head $(git branch --show-current) --json number,title,state` |

#### Step 3: Output the progress table

```
## Issue #<number>: Contribution Progress

| # | Step | Status | Notes |
|---|------|--------|-------|
| 1 | Verify bug on Git HEAD of correct branch | Done/TODO | <branch name, version> |
| 2 | Check ChangeLog for existing fix | Done/TODO | |
| 3 | Not targeting EOL branch | Done/TODO | <branch name> |
| 4 | Assess scope — small or large? | Done/TODO | <N lines changed> |
| 5 | Read coding standards | Done/TODO | https://www.freeradius.org/documentation/freeradius-server/4.0.0/developers/coding-methods.html |
| 6 | Build the server | Done/TODO | |
| 7 | Reproduce the bug | Done/TODO | |
| 8 | Write the fix | Done/TODO | <files changed> |
| 9 | Include test case | Done/TODO | <test file path> |
| 10 | Run existing tests | Done/TODO | |
| 11 | Commit on correct branch | Done/TODO | <commit hash> |
| 12 | Format PR description | Done/TODO | Triple backticks, escape #<num> |
| 13 | Open PR | Done/TODO | <PR URL or not yet> |
```

If any step is TODO, suggest the next action the user should take.
