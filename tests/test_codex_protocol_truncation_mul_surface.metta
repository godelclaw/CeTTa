!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqual
  (json-stringify
    (codex:truncation-policy-json
      (codex:truncation-policy-mul
        (codex:truncation-policy-bytes 9)
        1.5)))
  "{\"mode\":\"bytes\",\"limit\":14}")

!(assertEqual
  (json-stringify
    (codex:truncation-policy-json
      (codex:truncation-policy-mul
        (codex:truncation-policy-tokens 7)
        0.25)))
  "{\"mode\":\"tokens\",\"limit\":2}")
