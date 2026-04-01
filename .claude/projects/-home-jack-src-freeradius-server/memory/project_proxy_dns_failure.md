---
name: Proxy FQDN DNS failure analysis
description: Research on how a single DNS resolution failure during config load kills all proxy functionality — realms_init() aborts entirely if any home_server FQDN fails to resolve
type: project
---

## Problem

When FreeRADIUS proxy uses FQDNs for home servers, DNS resolution happens at config load time (not request time). If ANY single FQDN fails to resolve, the entire proxy configuration is abandoned — all pools, all realms, everything.

**Why:** `realms_init()` in `src/main/realms.c:2593-2594` calls `home_server_afrom_cs()` for each home_server in a loop. If any returns NULL (DNS failure), it jumps to `error:` which calls `realms_free()` and destroys ALL realms/pools.

**How to apply:** This is a potential defect to file upstream. The fix would involve skipping failed home servers with a warning instead of aborting the entire proxy config. Since it's more than a 1-2 line fix, contribution guidelines require contacting the dev team first via issue/mailing list before coding.

## Key Code Path

- `realms_init()` — `src/main/realms.c:2540`
- `home_server_afrom_cs()` — `src/main/realms.c:801-1205`
- DNS resolution: `fr_pton()` → `ip_hton()` → `getaddrinfo()` — `src/lib/misc.c:1110`
- Error handler: `src/main/realms.c:2627-2641` — `realms_free()` + `talloc_free(rc)` + `return 0`

## Impact

- Primary FQDN DNS fail → secondary never gets created
- No failover possible (pool never built)
- Server runs with zero proxy capability
- No retry — one-shot resolution at startup
- Same behavior on v3.2.x and master

## Status

- Filed as https://github.com/FreeRADIUS/freeradius-server/issues/5799 (2026-03-31)
- Affects both v3.2.x (realms.c) and master/v4 (module instantiation)
- Bug reproduced in devcontainer on v3.2.x HEAD
- v3.2.x "skip and continue" approach (fix/proxy-dns-graceful-skip) — deleted, maintainer said config errors should be fatal
- v4 deferred DNS approach (issue-5799-defer-fqdn-resolution) — on fork, resolves FQDN at conn_init() time so failure follows zombie/revive path
- v4 implementation tested: build clean, e2e proxy works for both IP and FQDN, bad FQDN retries via zombie/revive
- Code review found 3 concerns: config table duplication (~150 lines), fragile parent cast, ipv4addr/ipv6addr not deferred
- Waiting for maintainer (alandekok) response on #5799 before opening PR — may need rework based on feedback
