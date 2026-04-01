# Draft Issue: Single home_server FQDN resolution failure aborts entire proxy configuration

## Status: FILED — https://github.com/FreeRADIUS/freeradius-server/issues/5799

### What type of defect/bug is this?

Unexpected behaviour (obvious or verified by project member)

### How can the issue be reproduced?

Configure two home servers, one with an unresolvable FQDN, in proxy.conf:

```text
home_server good_server {
    type = auth
    ipaddr = 127.0.0.1
    port = 1812
    secret = testing123
}

home_server bad_server {
    type = auth
    ipaddr = this.fqdn.does.not.resolve.invalid
    port = 1812
    secret = testing123
}

home_server_pool my_pool {
    type = fail-over
    home_server = good_server
    home_server = bad_server
}

realm test.example.com {
    auth_pool = my_pool
}
```

Run `radiusd -CX`. The DNS failure for `bad_server` aborts the entire proxy configuration — `good_server`, the pool, and the realm are all discarded.

**Expected:** `bad_server` is skipped with a warning. `good_server` loads normally. The pool is created with degraded membership (or skipped with a warning). Other realms/pools unrelated to the failed server are unaffected.

### Root cause

**v3.2.x:** In `src/main/realms.c`, `realms_init()` iterates over all `home_server` sections (line 2588). If any `home_server_afrom_cs()` returns NULL (DNS failure via `fr_pton()` → `ip_hton()` → `getaddrinfo()`), the code does `goto error` (line 2594) which calls `realms_free()` and destroys ALL realms, pools, and home servers:

```c
home = home_server_afrom_cs(rc, rc, cs);
if (!home) goto error;          // one failure kills all
```

**master (v4):** The proxy architecture changed (home servers are now `rlm_radius` modules), but `modules_instantiate()` in `src/lib/server/module.c` (line 1322) has the same pattern — if any module instantiation fails, it returns -1 and the server won't start:

```c
if (module_instantiate(mi) < 0) return -1;
```

DNS resolution still happens at config parse time via `FR_TYPE_COMBO_IP_ADDR` → `fr_pton()` → `ip_hton()` → `getaddrinfo()`.

### Impact

- A temporary DNS outage during server restart/reload takes out ALL proxying
- No failover possible — pools are never constructed
- Affects any deployment using FQDNs for home servers (common in large deployments)
- No retry mechanism — resolution is one-shot at startup

### Proposed fix

For v3.2.x: change the `goto error` in the home_server parse loop to `continue` with a warning log, allowing other home servers to load. Pools referencing the failed server would be skipped (with warning). Realms referencing failed pools would also be skipped.

For master: similar approach at the module instantiation level, or handle DNS failure gracefully within `rlm_radius` bootstrap.

Happy to submit a PR for v3.2.x if the approach looks reasonable. The fix touches only `src/main/realms.c` — converting fatal errors to skip-and-warn in the `realms_init()` loops.

### Reproduction evidence

Tested on v3.2.x HEAD (v3.2.9), built in devcontainer (Ubuntu 24.04).

### Log output from the FreeRADIUS daemon

```shell
 home_server good_server {
 	nonblock = no
 	ipaddr = 127.0.0.1
 	...
 }
 home_server bad_server {
 	nonblock = no
/usr/local/etc/raddb/proxy.conf[10]: Failed parsing configuration item "ipaddr" - Failed resolving "this.fqdn.does.not.resolve.invalid" to IPv4 address: Name or service not known
```

Server output stops here. No "Configuration appears to be OK". The good_server, pool, and realm are silently discarded.

### Relevant log output from client utilities

_No response_

### Backtrace from LLDB or GDB

_No response_

---

## Implementation: Deferred DNS Resolution (master/v4)

**Branch:** `issue-5799-defer-fqdn-resolution`
**Files:** `src/modules/rlm_radius/{rlm_radius.c, rlm_radius.h, bio.c}`

### Approach

Instead of resolving FQDNs at config parse time, store the hostname and defer resolution to `conn_init()`. If DNS fails at connection time, `CONNECTION_STATE_FAILED` triggers the zombie/revive retry mechanism — same path as an unreachable IP.

### Test Results (2026-04-01)

- Build: clean on master
- `make test`: pass (2 pre-existing failures unrelated: linelog mount perms, totp missing oathtool)
- Config check with unresolvable FQDN: passes (deferred)
- Server startup with bad FQDN: starts, retries via INIT → FAILED → CLOSED cycle
- E2E proxy via IP literal: `Reply-Message = "proxied-ok"` from home server
- E2E proxy via FQDN (`homeserver.test`): `Reply-Message = "proxied-ok"` — same result

### Code Review Concerns

1. **Config table duplication (~150 lines)** — UDP/TCP/unconnected sub-configs duplicated from `fd_config.c` with only `.func = ipaddr_deferred_parse` added to the `ipaddr` entry. If upstream changes `fd_config.c`, these copies drift. Maintainers may prefer a hook-based approach in `fd_config.c` instead.

2. **Fragile parent pointer cast** — `ipaddr_deferred_parse()` casts `parent` (which is `fr_bio_fd_config_t *`) to `rlm_radius_t *`, relying on `fd_config` being at offset 0 in `rlm_radius_s`. The struct comment says "MUST be at the start!" but there's no compile-time assertion.

3. **`ipv4addr`/`ipv6addr` not deferred** — Only `ipaddr` (COMBO) gets deferred parse. Explicit `ipv4addr`/`ipv6addr` still resolve at config time. Probably intentional but worth noting.

### Status

- Waiting for maintainer (alandekok) response on #5799 before opening PR
- May need to rework based on feedback about the config duplication
