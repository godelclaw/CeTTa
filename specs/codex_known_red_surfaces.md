# Codex Known Red Surfaces

Last updated: 2026-06-10 on branch `exp/codex` after the models-endpoint and
network-proxy-loader materialization repair pass.

This file records Codex-in-CeTTa surfaces that are known red while the core
validation baseline remains green. They should not block unrelated slice work,
but they must be checked with output-aware validation because `./cetta` exits
`0` even when a test prints `[(Error ...)]`.

## Current Baseline

- `make test` passes.
- `scripts/check_codex_surfaces.sh` exits zero across the full
  `tests/test_codex_*.metta` and `examples/codex_*_demo.metta` sweep.
- There are currently no known red Codex surfaces.

## Resolved: `tests/test_codex_models_endpoint_surface.metta`

Resolved 2026-06-10. The failure was the order-sensitive evaluator case where a
value-producing zero-arg helper used after an earlier `assertEqualToResult`
returned no result, even though every lower-level piece reduced correctly in
isolation.

What fixed it, in `codex/models_endpoint.metta` and `codex/auth_provider.metta`:

- unwrapping result constructors through `(case (collapse $result) ...)`
  instead of `(case (once (eval $result)) ...)`
- splitting the request-plan construction into staged
  `request-plan-after-api-provider` / `request-plan-after-auth` helpers that
  pattern-match the resolve result constructors directly
- materializing the api-auth value with `(once (eval ...))` before telemetry
  projection, and computing auth-header telemetry by collapsing the header
  lookup rather than calling `headers-contains-key` then `headers-get` twice

The Rust request-plan algorithm itself was unchanged; the deviations are
evaluator-materialization workarounds and are commented at the implementation.

## Resolved: `tests/test_codex_network_proxy_loader_surface.metta`

Resolved 2026-06-10. Same evaluator family: a nested `apply-tables-value` call
inside a zero-arg fixture helper lost its value once later fixture definitions
were present.

What fixed it, in `codex/network_proxy_loader.metta` and
`codex/network_proxy_spec.metta`:

- `network-proxy-loader-result-value` / `-error-message` unwrap through
  `(case (collapse $result) ...)` instead of constructor-only equations
- the settings/config getters destructure the full
  `CodexNetworkProxySettings` constructor in the equation head instead of
  chaining through intermediate getter calls

The Rust overlay algorithm was unchanged.

## Follow-up

The underlying evaluator behavior — a zero-arg helper losing its value when
used after earlier assertions or fixture definitions — is still unfixed in the
runtime. A minimal evaluator regression test (no Codex modules) is still worth
building so the workaround idioms above can eventually be removed.
