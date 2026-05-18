!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:account)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:rate-limit-snapshot-json
      (codex:rate-limit-snapshot
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        (codex:plan-type-self-serve-business-usage-based)
        CodexAbsent)))
  ("{\"limit_id\":null,\"limit_name\":null,\"primary\":null,\"secondary\":null,\"credits\":null,\"plan_type\":\"self_serve_business_usage_based\",\"rate_limit_reached_type\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:rate-limit-snapshot-json
      (codex:rate-limit-snapshot
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        (codex:plan-type-pro-lite)
        CodexAbsent)))
  ("{\"limit_id\":null,\"limit_name\":null,\"primary\":null,\"secondary\":null,\"credits\":null,\"plan_type\":\"prolite\",\"rate_limit_reached_type\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:rate-limit-snapshot-json
      (codex:rate-limit-snapshot
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        (codex:plan-type-plus)
        CodexAbsent)))
  ("{\"limit_id\":null,\"limit_name\":null,\"primary\":null,\"secondary\":null,\"credits\":null,\"plan_type\":\"plus\",\"rate_limit_reached_type\":null}"))
