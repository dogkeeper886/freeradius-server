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
