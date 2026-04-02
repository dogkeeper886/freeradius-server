# Testing

Include test cases in PRs when possible. Three test frameworks:

- **Unit tests**: `src/tests/unit/*.txt` — conditions, protocol encoders/decoders
- **Module tests**: `src/tests/modules/` — module functionality
- **Unlang tests**: `src/tests/unlang/` — unlang keywords and functions

See README files in each test directory. Use existing tests as examples. CI runs on every PR.
