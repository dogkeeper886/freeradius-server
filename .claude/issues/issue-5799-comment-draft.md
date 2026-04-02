Thanks for the explanation. I understand the intent of `radiusd -C` and that DNS failure represents a real configuration problem.

However, I'd like to point out an inconsistency in how the server handles similar failure scenarios:

- **Unreachable IP address at boot**: The server starts successfully. Socket creation succeeds, the connection fails asynchronously, and the zombie/dead/revive mechanism handles it gracefully. Other home_servers continue to work.
- **Unresolvable FQDN at boot**: The server refuses to start entirely. All home_servers go down, even the ones with valid addresses.

What do you think about deferring DNS resolution to connection init time, so an unresolvable FQDN follows the same async failure and revive path as an unreachable IP?
