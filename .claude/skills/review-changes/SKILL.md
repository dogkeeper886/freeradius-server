---
name: review-changes
description: Review modified FreeRADIUS source files for coding standards, minimal diff, and test coverage. Auto-invoke after modifying .c, .h, or unlang/config files in this repo.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git status:*)
---

## Post-Change Review

Review the current changes against FreeRADIUS contribution standards.

### Current Changes

- Diff: !`git diff --stat`
- Modified files: !`git diff --name-only`
- Staged: !`git diff --cached --name-only`

### Checks

For each modified file, verify:

#### 1. Minimal and focused
- Only lines relevant to the task are changed
- No unrelated reformatting, whitespace changes, or comment additions
- No speculative abstractions or "while I'm here" improvements

#### 2. Coding standards
Reference: https://www.freeradius.org/documentation/freeradius-server/4.0.0/developers/coding-methods.html

Check the diff for:
- Tab indentation (not spaces)
- Braces on same line as control statement
- No trailing whitespace
- Function names: `module_verb_noun` convention
- No C99-style `//` comments in `.c` files (use `/* */`)

#### 3. Test coverage
- If a bug fix: is there a test that would have caught it?
- Check if relevant test files exist under `src/tests/unit/`, `src/tests/modules/`, or `src/tests/unlang/`
- If no test exists and one is feasible, note it

#### 4. Contribution readiness
- Changes target the correct branch for the issue
- No debug prints or temporary code left in
- No new compiler warnings introduced (check for obvious issues like unused variables)

### Output

Brief assessment (under 10 lines):
- List any issues found, with file and line reference
- If clean, say so in one line
- Do NOT repeat what was changed — the user can see the diff
