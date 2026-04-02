# Plan: Defer FQDN Resolution to Connection Init Time

## Context

Issue FreeRADIUS/freeradius-server#5799. When `ipaddr` in an `rlm_radius` config is an FQDN, DNS resolution happens during config parsing. If DNS fails, the entire server refuses to start. But an unreachable IP starts fine — the zombie/revive mechanism handles it gracefully. We want FQDNs to follow the same path.

## Approach

Keep changes entirely within `rlm_radius`. Duplicate the transport sub-config arrays with a custom `.func` on `ipaddr` that tries literal IP first, falls back to storing the hostname string. Resolve DNS in `conn_init()` — on failure, return `CONNECTION_STATE_FAILED` which feeds into zombie/revive (same as unreachable IP). On revive, `conn_init()` is called again, retrying DNS.

## Files Modified (3 files)

### 1. `src/modules/rlm_radius/rlm_radius.h`

- Added `char const *dst_hostname` field to `rlm_radius_t` struct

### 2. `src/modules/rlm_radius/rlm_radius.c`

- `ipaddr_deferred_parse()` — custom `.func` that tries `fr_inet_pton(resolve=false)` first; if not a literal IP, stores hostname string
- Duplicated transport sub-configs (`rlm_radius_udp_sub_config`, `rlm_radius_tcp_sub_config`, etc.) with `.func = ipaddr_deferred_parse` on ipaddr entry
- Duplicated unconnected config for XLAT_PROXY/UNCONNECTED_REPLICATE modes (no ipaddr, no DNS concern)
- `rlm_radius_transport_parse()` — local transport parse using new configs
- `rlm_radius_fd_client_config[]` — replaces `fr_bio_fd_client_config` in `module_config[]`
- `mod_instantiate()` — skip `fr_bio_fd_check_config()` dst_ipaddr validation when hostname is deferred, still validate port

### 3. `src/modules/rlm_radius/bio.c`

- Added `char const *dst_hostname` to `bio_handle_ctx_t`
- `mod_thread_instantiate()` — propagate `inst->dst_hostname` to thread context
- `conn_init()` — resolve hostname via `fr_inet_hton()` before `fr_bio_fd_alloc()`. On failure, `goto fail` → `CONNECTION_STATE_FAILED` → zombie/revive retries

## Lifecycle

| Stage | Literal IP (unchanged) | FQDN (new) |
|-------|----------------------|-------------|
| Config parse | `fr_inet_pton` resolves → `dst_ipaddr` set | `fr_inet_pton(resolve=false)` fails → hostname stored, `dst_ipaddr` stays `AF_UNSPEC` |
| Boot validation | `fr_bio_fd_check_config` passes | Skip dst_ipaddr check (hostname pending) |
| `conn_init()` | Uses `dst_ipaddr` directly | `fr_inet_hton()` resolves hostname → sets `dst_ipaddr` |
| DNS/connect fails | `CONNECTION_STATE_FAILED` | Same: `CONNECTION_STATE_FAILED` |
| Zombie/revive | `conn_init()` retries with same IP | `conn_init()` retries DNS resolution |

## Remaining Work

- [ ] Build and fix any compilation errors
- [ ] Docker test: `freeradius -C` with unresolvable FQDN → exit 0
- [ ] Docker test: `freeradius -C` with resolvable FQDN → exit 0
- [ ] Docker test: `freeradius -C` with literal IP → exit 0 (no regression)
- [ ] Runtime test: server starts with unresolvable FQDN, home_server goes through zombie/revive
- [ ] Run `/contribute` checklist before PR submission
