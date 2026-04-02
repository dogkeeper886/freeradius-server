# FreeRADIUS Contribution Guide

This is a fork of https://github.com/FreeRADIUS/freeradius-server for contributing upstream.

## Repo Setup

- `origin` — upstream FreeRADIUS/freeradius-server (read-only)
- `fork` — dogkeeper886/freeradius-server (our fork, push here)
- Dev files (CLAUDE.md, .claude/, .devcontainer/) live on the fork only
- **PR branches must be based on `origin/<branch>`, not `fork/<branch>`**, so dev files are excluded from PR diffs

## Branches

- `master` — v4.x development (default target for PRs)
- `v3.2.x` — current stable
- `v3.0.x` — older stable
- Do not target EOL branches

## Dev Environment

A `.devcontainer` is set up for this project (Ubuntu 24.04). It installs all build dependencies automatically using `mk-build-deps` from `debian/control`.

```
./configure
make -j$(nproc)
```

Run in debug mode:
```
build/bin/local/radiusd -X
```

Verify config without starting:
```
build/bin/local/radiusd -C
```

## Guidelines

- Upstream contribution rules: @.claude/rules/contributing.md
- Testing instructions: @.claude/rules/testing.md
