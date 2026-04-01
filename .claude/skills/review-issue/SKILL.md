---
name: review-issue
description: Review FreeRADIUS GitHub issues against the contribution guidelines before picking one up. Use when evaluating whether an issue is suitable to work on.
argument-hint: "[issue-number or blank to scan open issues]"
allowed-tools: Bash(gh *), Bash(python3 *), WebFetch, Read, Grep, Glob
---

## Review FreeRADIUS Issues for Contribution

Evaluate GitHub issues from FreeRADIUS/freeradius-server against the project's contribution guidelines to find one suitable to pick up.

### Input

- `$ARGUMENTS` — optional issue number to review a single issue

### Mode 1: No argument — Scan open issues

When no argument is provided, scan open issues in bulk and filter for pickable ones.

#### Step 1: Fetch open issues (with comments) and all PRs in parallel

Run these THREE commands in parallel — never sequentially:

```bash
gh issue list --repo FreeRADIUS/freeradius-server --state open --label "defect" --limit 20 --json number,title,labels,createdAt,comments
```

```bash
gh issue list --repo FreeRADIUS/freeradius-server --state open --label "feature enhancement" --limit 10 --json number,title,labels,createdAt,comments
```

```bash
gh pr list --repo FreeRADIUS/freeradius-server --state all --limit 100 --json number,title,state
```

#### Step 2: Cross-reference issues against PRs and comments

Use a SINGLE python3 script to process all data at once. The script must:

1. **Match PRs to issues**: Search PR titles for issue numbers (`#NNNN`) and keywords from issue titles. Mark issues with OPEN or recently MERGED PRs as TAKEN.
2. **Check comments for claims**: Scan issue comments for phrases like "will send a patch", "I will fix", "working on", "I will have a look", "sending a pr", "submitted a pr". Mark these as CLAIMED.
3. **Filter out**: issues that are TAKEN or CLAIMED.
4. **Classify remaining issues**:
   - Type: defect / feature (from labels)
   - Branch: from labels (v3.2.x, v4.0.x) or assume master
   - EOL check: skip if v3.0.x or below
5. **Output** the filtered list.

IMPORTANT: This MUST be a single batch operation. NEVER loop `gh` commands per issue.

#### Step 3: Present a shortlist

Output a table of pickable issues sorted by difficulty (easiest first):

```
| # | Issue | Type | Branch | Difficulty | Summary |
|---|-------|------|--------|-----------|---------|
| 1 | #XXXX | defect | v3.2.x | Easy | ... |
| 2 | #YYYY | feature | master | Medium | ... |
```

Then ask the user which one they want to review in detail.

### Mode 2: Single issue — Deep review

When `$ARGUMENTS` is provided, do a full review of that specific issue.

#### Step 1: Fetch issue details AND all PRs in parallel

Run these TWO commands in parallel:

```bash
gh issue view $ARGUMENTS --repo FreeRADIUS/freeradius-server --json number,title,body,labels,author,createdAt,comments
```

```bash
gh pr list --repo FreeRADIUS/freeradius-server --state all --limit 100 --json number,title,state,body
```

#### Step 2: Cross-reference

Use python3 to match PRs against this issue number and title keywords. Also check comments for claims. This is the same batch approach as Mode 1 but for a single issue.

#### Step 3: Classify the issue

- **Defect** (`defect` label) — a bug report
- **Feature** (`feature enhancement` label) — a feature request
- **Support question** — someone asking for help configuring the server (REJECT)
- **Security issue** — remotely exploitable vulnerability (REJECT)

#### Step 4: Check against contribution guidelines

| # | Check | How to Verify |
|---|-------|---------------|
| 1 | **Not a support question** | Issue describes a defect or feature, not "how do I configure X?" |
| 2 | **Not a security issue** | No remotely exploitable vulnerability described |
| 3 | **Not targeting an EOL branch** | Check labels. v3.0.x and below are EOL. |
| 4 | **Has reproduction steps** (defects only) | Steps to reproduce, config snippets, or `radiusd -X` output |
| 5 | **Not already fixed** | Check recent commits: `gh api repos/FreeRADIUS/freeradius-server/commits --jq '.[].commit.message' \| head -30` |
| 6 | **Scope assessment** | Small fix (1-2 lines, can PR directly) or large (contact dev team first)? |
| 7 | **Not claimed by someone else** | No open PR, no "I'll fix this" in comments |

#### Step 5: Assess difficulty

- **Easy** — typo, doc update, config file change, dictionary addition, 1-2 line code fix
- **Medium** — bug fix in a single module, missing feature in existing module, schema changes
- **Hard** — multi-file changes, new module, memory management, race conditions, protocol changes

#### Step 6: Output the review

```
## Issue #<number>: <title>

**Type**: Defect / Feature / Other
**Branch**: master / v3.2.x / v3.0.x
**Difficulty**: Easy / Medium / Hard

### Guideline Checks
- [ ] Not a support question
- [ ] Not a security issue
- [ ] Not targeting EOL branch
- [ ] Has reproduction steps (defects)
- [ ] Not already fixed
- [ ] Not claimed (no PR, no one working on it)
- [ ] Scope: small fix (can PR directly) / large (contact dev team first)

### Summary
<What the issue is about in 2-3 sentences>

### What Needs to Change
<Files and logic that likely need modification>

### Recommendation
PICK UP / SKIP / NEEDS MORE INFO

<Reason for recommendation>
```

### Important Rules

- If the issue is a support question, recommend SKIP — it belongs on the mailing list.
- If the issue targets an EOL branch, recommend SKIP.
- If an open PR already exists, recommend SKIP unless the PR is stale (>6 months with no activity).
- If someone claimed the work in comments, recommend SKIP.
- If the issue is a large feature, note that the dev team must be contacted first.
- Always check the ChangeLog and recent commits before recommending PICK UP.
- NEVER loop `gh` commands per issue. Always fetch in bulk and cross-reference locally with python3.
