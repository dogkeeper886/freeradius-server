# Upstream Contribution Rules

Full guidelines: https://github.com/FreeRADIUS/freeradius-server?tab=contributing-ov-file

## Issue Tracker

- Defect reports, feature requests, and PRs ONLY
- Never post support or config questions as issues — they will be closed/locked, repeat offenders get banned
- Report security vulnerabilities to security@freeradius.org, NOT on GitHub
- Do not report defects for EOL branches — they will be closed and locked
- Before reporting a defect, verify it exists on Git HEAD of the appropriate branch
- Wrap all log output in triple backticks to prevent GitHub auto-linking `#<num>` strings

## Pull Requests

- Small 1-2 line fixes: open a PR directly, no prior discussion needed
- Large features, new modules, or big code changes: contact the dev team FIRST via the devel mailing list (https://freeradius.org/support/) or GitHub issue tracker. Wait for go-ahead before coding
- Dictionary PRs must target both `master` and `v3.0.x` branches

## Coding Standards

- Style guide: https://www.freeradius.org/documentation/freeradius-server/4.0.0/developers/coding-methods.html
- New modules: https://www.freeradius.org/documentation/freeradius-server/4.0.0/developers/module_interface.html
- API docs: https://doc.freeradius.org (updated within 1 minute of each commit to master)
