# FreeRADIUS Contribution Guide

This project is a fork/clone of https://github.com/FreeRADIUS/freeradius-server for contributing upstream.

## Goal

Study and contribute to the FreeRADIUS project. Focus areas:
- Fix defects and improve reliability (proxy, IPv6, module bugs)
- Learn FreeRADIUS internals through hands-on contribution
- Follow upstream contribution guidelines strictly

## Repo Setup

- `origin` — upstream FreeRADIUS/freeradius-server (read-only)
- `fork` — dogkeeper886/freeradius-server (our fork, push here)
- Dev files (CLAUDE.md, .claude/, .devcontainer/) live on the fork only
- **PR branches must be based on `origin/<branch>`, not `fork/<branch>`**, so dev files are excluded from PR diffs

## Rules

- The GitHub issue tracker is for defect reports, feature requests, and PRs ONLY. Never post support or config questions as issues — they will be closed/locked, repeat offenders get banned.
- Report security vulnerabilities to security@freeradius.org, NOT on GitHub.
- Do not report defects for EOL branches — they will be closed and locked.
- Before reporting a defect, verify it exists on Git HEAD of the appropriate branch.
- Wrap all log output in triple backticks to prevent GitHub auto-linking `#<num>` strings.

## Pull Request Rules

- Small 1-2 line fixes: open a PR directly, no prior discussion needed.
- Large features, new modules, or big code changes: contact the dev team FIRST via the devel mailing list (https://freeradius.org/support/) or GitHub issue tracker. Wait for go-ahead before coding.
- Dictionary PRs must target both `master` and `v3.0.x` branches.

## Branches

- `master` — v4.x development (default target for PRs)
- `v3.2.x` — current stable
- `v3.0.x` — older stable
- Do not target EOL branches.

## Coding Standards

Follow: https://www.freeradius.org/documentation/freeradius-server/4.0.0/developers/coding-methods.html

For new modules: https://www.freeradius.org/documentation/freeradius-server/4.0.0/developers/module_interface.html

API docs: https://doc.freeradius.org (updated within 1 minute of each commit to master)

## Testing

Include test cases in PRs when possible. Three test frameworks:

- Unit tests: `src/tests/unit/*.txt` — conditions, protocol encoders/decoders
- Module tests: `src/tests/modules/` — module functionality
- Unlang tests: `src/tests/unlang/` — unlang keywords and functions

See README files in each test directory. Use existing tests as examples. CI runs on every PR.

## Dev Environment

A `.devcontainer` is set up for this project (Ubuntu 24.04). It installs all build dependencies automatically using `mk-build-deps` from `debian/control`.

To build manually inside the container:
```
./configure
make -j$(nproc)
```

To run the server in debug mode:
```
build/bin/local/radiusd -X
```

To verify config without starting:
```
build/bin/local/radiusd -C
```
