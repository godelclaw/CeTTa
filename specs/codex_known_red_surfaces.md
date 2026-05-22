# Codex Known Red Surfaces

Last updated: 2026-05-22 on branch `exp/codex` after the tool registry builder
planning pass.

This file records Codex-in-CeTTa surfaces that are known red while the core
validation baseline remains green. They should not block unrelated slice work,
but they must be checked with output-aware validation because `./cetta` exits
`0` even when a test prints `[(Error ...)]`.

## Current Baseline

- `make -s` passes.
- `scripts/check_codex_surfaces.sh` exits nonzero only for the two deferred
  surfaces documented below. Rechecked after the tool registry builder planning
  pass.
- The dynamic tool registry surface is green in
  `tests/test_codex_tool_registry_plan_surface.metta`, including handler
  registration and coalesced namespace specs.
- The dynamic tool handler planning surface is green in
  `tests/test_codex_dynamic_tool_handler_surface.metta`, including request and
  response event projection plus cancellation handling.
- The tool registry builder planning surface is green in
  `tests/test_codex_tool_registry_builder_plan_surface.metta`, including
  dynamic handler binding transfer from the registry plan.
- Four cross-module repair surfaces remain green:
  - `tests/test_codex_approval_surface.metta`
  - `tests/test_codex_config_permissions_warnings_surface.metta`
  - `tests/test_codex_permissions_instructions_prefix_surface.metta`
  - `tests/test_codex_unified_exec_sandbox_session_surface.metta`
- The js_repl surface group is green, including:
  - `tests/test_codex_js_repl_surface.metta`
  - `tests/test_codex_js_repl_handler_surface.metta`
  - `tests/test_codex_js_repl_events_surface.metta`
  - `tests/test_codex_js_repl_summary_surface.metta`
  - `tests/test_codex_js_repl_summary_tail_surface.metta`
  - `tests/test_codex_js_repl_kernel_surface.metta`
  - `examples/codex_js_repl_demo.metta`

## `tests/test_codex_models_endpoint_surface.metta`

Reproduce:

```bash
./cetta --lang he --profile he_extended tests/test_codex_models_endpoint_surface.metta
```

Current first failure:

```text
(Error
  (assertEqualToResult
    (test:request-plan-fields (test:models-endpoint-provider-env-request-plan))
    (("0.124.0" "/models" 5000 "http://localhost:1234/v1"
      "model-header-value" "Bearer sk-provider")))
  "mismatch")
```

Observed shape:

- The failing assertion starts at test line 199.
- The same request-plan expression can produce the expected plan before the
  preceding auth-env assertion at lines 184-197 is present.
- After that assertion is present, direct use through
  `test:request-plan-fields` returns no result, while lower-level pieces still
  reduce correctly in isolation:
  - `test:models-endpoint-env-values`
  - `codex:models-endpoint-env-values-get`
  - `codex:model-provider-info-to-api-provider-from-env-values`
  - `codex:resolve-provider-auth-from-env-value`
  - `codex:collect-auth-env-telemetry-from-env-values`

Avoid repeating:

- Broadly rewriting `codex:openai-models-endpoint-request-plan-value` around
  `collapse` or constructor-only unwrapping did not fix the full surface.
- Splitting auth-env telemetry by boolean literal or inlining the request-plan
  telemetry construction either did not change the failure or regressed the
  earlier auth-env assertion.
- The failure currently looks like a CeTTa evaluation/materialization boundary
  issue exposed by assertion order, not a Rust algorithm mismatch in the
  request-plan construction itself.

Recommended next pass:

- Build a minimal evaluator regression around a value-producing zero-arg helper
  used both directly and as a pattern-matched argument after an earlier
  `assertEqualToResult`.
- Keep `models_endpoint.metta` algorithmically aligned with Rust while fixing
  the evaluator/materialization behavior or adding the narrowest justified
  public-boundary materializer.

## `tests/test_codex_network_proxy_loader_surface.metta`

Reproduce:

```bash
./cetta --lang he --profile he_extended tests/test_codex_network_proxy_loader_surface.metta
```

Current first failure:

```text
(Error
  (assertEqual
    (codex:network-proxy-config-allowed-domains (overlay-config))
    ("lower.example.com" "higher.example.com"))
  "Expected: [(\"lower.example.com\" \"higher.example.com\")]\nGot: []\n...")
```

Observed shape:

- The failing assertion starts at test line 148.
- Direct first-layer application works:
  `apply-tables-value` over `codex:network-proxy-config-default` and
  `overlay-lower-tables` returns the expected config.
- Direct nested application can work in smaller temp files, but the zero-arg
  helper `overlay-config` loses the result in the full surface.
- A manual expansion of the body equivalent to
  `codex:network-proxy-loader-apply-network-tables` can produce the expected
  merged config, so the Rust overlay algorithm appears intact.

Avoid repeating:

- Replacing `network-proxy-loader-result-value` with a generic `collapse`
  unwrap did not fix the full surface and can break direct application.
- Adding getter overloads for
  `(codex:network-proxy-loader-result-value ...)` did not affect the full
  source-loaded test.
- Constructor-specific overloads for
  `codex:network-proxy-loader-apply-network-tables` helped in isolated temp
  probes but did not fix the full surface.

Recommended next pass:

- Minimize the evaluator case where a nested `apply-tables-value` call inside a
  zero-arg helper loses its value only after later fixture definitions are
  present.
- Treat this as a materialization/order-sensitive evaluator issue until proven
  otherwise; do not change the network table overlay algorithm without a
  comment justifying a Rust-to-CeTTa paradigm constraint.
