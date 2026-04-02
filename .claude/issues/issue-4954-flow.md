# Issue #4954: fr_pton6 IPv6 scope bug — Flow Diagram

## Bug Overview

```
                         E2E Flow: Issue #4954
                         =====================

  radclient                    radiusd (v3.2.x)                    SQLite
  ─────────                    ────────────────                    ──────
      │                              │                                │
      │  Access-Request (IPv6)       │                                │
      │  User-Name = testuser        │                                │
      │  NAS-IPv6-Address = ::1      │                                │
      │─────────────────────────────>│                                │
      │                              │                                │
      │                              │  1. AUTHORIZE                  │
      │                              │─────────────────────────────-->│
      │                              │  SELECT FROM radcheck          │
      │                              │  WHERE username = 'testuser'   │
      │                              │<──────────────────────────────-│
      │                              │  Cleartext-Password, Simul := 2│
      │                              │                                │
      │                              │  2. AUTHENTICATE (PAP)        │
      │                              │  password matches ✓            │
      │                              │                                │
      │                              │  3. SESSION CHECK              │
      │                              │─────────────────────────────-->│
      │                              │  SELECT COUNT(*) FROM radacct  │
      │                              │  WHERE username = 'testuser'   │
      │                              │  AND acctstoptime IS NULL      │
      │                              │<──────────────────────────────-│
      │                              │  count = 2 (>= Simul-Use 2)   │
      │                              │                                │
      │                              │  4. VERIFY SESSIONS            │
      │                              │─────────────────────────────-->│
      │                              │  SELECT nasipaddress, ...      │
      │                              │  FROM radacct WHERE ...        │
      │                              │<──────────────────────────────-│
      │                              │  row: nasipaddress = "::1"     │
      │                              │                                │
      │                              │  5. rad_check_ts()             │
      │                              │                                │
      │                              │  ┌─────────────────────────┐   │
      │                              │  │ fr_pton("::1")          │   │
      │                              │  │                         │   │
      │                              │  │ fr_ipaddr_t nas_addr;   │   │
      │                              │  │ (stack — NOT zeroed)    │   │
      │                              │  │                         │   │
      │                              │  │ fr_pton6() sets:        │   │
      │                              │  │   .af     = AF_INET6    │   │
      │                              │  │   .prefix = 128         │   │
      │                              │  │   .addr   = ::1         │   │
      │                              │  │   .scope  = ???         │   │
      │                              │  └────────────┬────────────┘   │
      │                              │               │                │
      │                              │               ▼                │
      │                              │  ┌─────────────────────────┐   │
      │                              │  │ client_find_old(&nas_addr)  │
      │                              │  │                         │   │
      │                              │  │ Searches root_clients   │   │
      │                              │  │ tree using              │   │
      │                              │  │ fr_ipaddr_cmp()         │   │
      │                              │  │                         │   │
      │                              │  │ Compares:               │   │
      │                              │  │  .af     ✓ match        │   │
      │                              │  │  .prefix ✓ match        │   │
      │                              │  │  .scope  ? ...          │   │
      │                              │  └────────────┬────────────┘   │
      │                              │               │                │
      │                      ┌───────┴───────┐       │                │
      │                      │               │       │                │
      │                      ▼               ▼       │                │
      │               WITHOUT FIX      WITH FIX      │                │
      │              ┌───────────┐   ┌───────────┐   │                │
      │              │.scope =   │   │.scope = 0 │   │                │
      │              │ 0xABABABAB │   │           │   │                │
      │              │(garbage)  │   │(initialized)  │                │
      │              └─────┬─────┘   └─────┬─────┘   │                │
      │                    │               │         │                │
      │                    ▼               ▼         │                │
      │              stored client   stored client   │                │
      │              .scope = 0      .scope = 0      │                │
      │                    │               │         │                │
      │              0 != 0xABAB     0 == 0          │                │
      │              MISMATCH ✗      MATCH ✓         │                │
      │                    │               │         │                │
      │                    ▼               ▼         │                │
      │              cl = NULL       cl = found      │                │
      │                    │               │         │                │
      │                    ▼               ▼         │                │
      │              "Unknown NAS"   "No NAS type,   │                │
      │              return 1        or type other"  │                │
      │              (trust radutmp) return 1        │                │
      │              session NOT     session IS      │                │
      │              verified ✗      verified ✓      │                │
      │                              │                                │
      │  Access-Reject               │                                │
      │  "already logged in"         │                                │
      │<─────────────────────────────│                                │
      │                              │                                │
```

## Real-World Impact (nas_type = cisco)

```
WITHOUT FIX                          WITH FIX
───────────                          ────────
client_find_old() = NULL             client_find_old() = found
  │                                    │
  ▼                                    ▼
"Unknown NAS, not checking"          nas_type = "cisco"
return 1 (assume logged in)            │
  │                                    ▼
  │                                  exec checkrad cisco ::1 ...
  │                                    │
  │                                    ├─ NAS says user online → return 1
  │                                    └─ NAS says user offline → return 0
  │                                         │
  │                                         ▼
  │                                    zap stale session
  │                                    count drops to 1
  │                                         │
  ▼                                         ▼
REJECT (wrongly)                     ACCEPT (correctly)
```

## E2E Test Data

```
                    E2E Test: Issue #4954
                    =====================

  SQLite DB (pre-seeded):
  ┌─────────────────────────────────────────────────────┐
  │ radcheck:                                           │
  │   testuser | Cleartext-Password := password         │
  │   testuser | Simultaneous-Use := 2                  │
  │                                                     │
  │ radacct (active sessions):                          │
  │   session001 | testuser | nasipaddress=::1 | port=1 │
  │   session002 | testuser | nasipaddress=::1 | port=2 │
  └─────────────────────────────────────────────────────┘

  radiusd config:
  ┌─────────────────────────────────────────────────────┐
  │ client localhost_ipv6 {                             │
  │     ipv6addr = ::1                                  │
  │     secret = testing123                             │
  │     nas_type = other    ◄── key: "other" trusts     │
  │ }                           session without checkrad│
  └─────────────────────────────────────────────────────┘


  radclient                         radiusd                          SQLite
  ─────────                         ───────                          ──────
      │                                │                                │
      │ Access-Request                 │                                │
      │ User-Name = testuser           │                                │
      │ User-Password = password       │                                │
      │ NAS-IPv6-Address = ::1         │                                │
      │ NAS-Port = 2                   │                                │
      │───────────────────────────────>│                                │
      │                                │                                │
      │                          1. AUTHORIZE                           │
      │                                │──────────────────────────────>│
      │                                │ SELECT FROM radcheck          │
      │                                │ WHERE username = 'testuser'   │
      │                                │<─────────────────────────────│
      │                                │ Cleartext-Password := password│
      │                                │ Simultaneous-Use := 2         │
      │                                │                                │
      │                          2. AUTHENTICATE                        │
      │                                │ PAP: password matches ✓        │
      │                                │                                │
      │                          3. SESSION: simul_count_query          │
      │                                │──────────────────────────────>│
      │                                │ SELECT COUNT(*) FROM radacct  │
      │                                │ WHERE username='testuser'     │
      │                                │ AND acctstoptime IS NULL      │
      │                                │<─────────────────────────────│
      │                                │ count = 2                     │
      │                                │                                │
      │                                │ 2 >= Simultaneous-Use(2)      │
      │                                │ → must verify each session    │
      │                                │                                │
      │                          4. SESSION: simul_verify_query         │
      │                                │──────────────────────────────>│
      │                                │ SELECT nasipaddress, ...      │
      │                                │ FROM radacct                  │
      │                                │ WHERE username='testuser'     │
      │                                │ AND acctstoptime IS NULL      │
      │                                │<─────────────────────────────│
      │                                │ row1: nasipaddress = "::1"   │
      │                                │ row2: nasipaddress = "::1"   │
      │                                │                                │
      │                          5. FOR EACH ROW: rad_check_ts()        │
      │                                │                                │
      │                    ┌────────────────────────┐                   │
      │                    │ fr_ipaddr_t nas_addr;  │                   │
      │                    │ (stack variable)       │                   │
      │                    │                        │                   │
      │                    │ fr_pton("::1", &nas_addr)                  │
      │                    │   → af     = 10 (AF_INET6)                │
      │                    │   → prefix = 128                          │
      │                    │   → addr   = ::1                          │
      │                    │   → scope  = 0  ◄── THE FIX              │
      │                    │             (was garbage without fix)      │
      │                    └──────────────┬─────────┘                   │
      │                                   │                             │
      │                    ┌──────────────▼─────────┐                   │
      │                    │ client_find_old(&nas_addr)                 │
      │                    │                        │                   │
      │                    │ stored client ::1:     │                   │
      │                    │   af=10, prefix=128    │                   │
      │                    │   addr=::1, scope=0    │                   │
      │                    │                        │                   │
      │                    │ fr_ipaddr_cmp:         │                   │
      │                    │   af     10==10  ✓     │                   │
      │                    │   prefix 128==128 ✓    │                   │
      │                    │   scope  0==0     ✓ ◄── works with fix    │
      │                    │   addr   ::1==::1 ✓    │                   │
      │                    │                        │                   │
      │                    │ FOUND: localhost_ipv6  │                   │
      │                    └──────────────┬─────────┘                   │
      │                                   │                             │
      │                                   ▼                             │
      │                    nas_type = "other"                            │
      │                    → "No NAS type, or type other, not checking" │
      │                    → return 1 (user IS logged in)               │
      │                                   │                             │
      │                    (same for row2) │                             │
      │                                   ▼                             │
      │                    simul_count = 2, Simultaneous-Use = 2        │
      │                    2 >= 2 → REJECT                              │
      │                                │                                │
      │ Access-Reject                  │                                │
      │ "You are already logged in     │                                │
      │  - access denied (2)"          │                                │
      │<───────────────────────────────│                                │


  ════════════════════════════════════════════════════════════════
  WHAT HAPPENS WITHOUT THE FIX (scope = 0xABABABAB garbage):
  ════════════════════════════════════════════════════════════════

      │                    fr_ipaddr_cmp:
      │                      af     10==10      ✓
      │                      prefix 128==128    ✓
      │                      scope  0xAB..!=0   ✗ FAIL
      │                                │
      │                      client_find_old → NULL
      │                                │
      │                      "Unknown NAS ::1, not checking"
      │                      return 1 (blindly trust)
      │                                │
      │                    Same result (reject) BUT:
      │                    ─────────────────────────
      │                    • NAS was NEVER verified
      │                    • Stale sessions can NEVER be cleaned
      │                    • With nas_type=cisco, checkrad would
      │                      never run → users permanently locked out
```
