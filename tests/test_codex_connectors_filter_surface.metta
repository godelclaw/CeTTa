!(register-module! ../codex)
!(import! &self codex:connectors_filter)
!(import! &self codex:context_fragment)

(= (codex-test-connector-app $id)
   (codex:app-info $id $id True True))

(= (codex-test-connector-app-ids ())
   ())

(= (codex-test-connector-app-ids $connectors)
   (let $head (list:first $connectors)
     (let $tail (list:rest $connectors)
       (list:append
         ((codex:app-info-id $head))
         (codex-test-connector-app-ids $tail)))))

!(assertEqualToResult
  (codex:connectors-filter-disallowed-connector-prefix)
  ("connector_openai_"))

!(assertEqualToResult
  (codex:connectors-filter-is-connector-id-allowed
    "asdk_app_hidden"
    "codex_cli")
  (True))

!(assertEqualToResult
  (codex:connectors-filter-is-connector-id-allowed
    "connector_openai_foo"
    "codex_cli")
  (False))

!(assertEqualToResult
  (codex:connectors-filter-is-connector-id-allowed
    "connector_3f8d1a79f27c4c7ba1a897ab13bf37dc"
    "codex_cli")
  (False))

!(assertEqualToResult
  (codex:connectors-filter-is-connector-id-allowed
    "connector_0f9c9d4592e54d0a9a12b3f44a1e2010"
    "codex_atlas")
  (False))

!(assertEqualToResult
  (codex:connectors-filter-is-connector-id-allowed
    "asdk_app_6938a94a61d881918ef32cb999ff937c"
    "codex_atlas")
  (True))

!(assertEqualToResult
  (codex-test-connector-app-ids
    (codex:connectors-filter-disallowed-connectors
      ((codex-test-connector-app "asdk_app_hidden")
       (codex-test-connector-app "alpha"))
      "codex_cli"))
  (("asdk_app_hidden" "alpha")))

!(assertEqualToResult
  (codex-test-connector-app-ids
    (codex:connectors-filter-disallowed-connectors
      ((codex-test-connector-app "connector_openai_foo")
       (codex-test-connector-app "connector_openai_bar")
       (codex-test-connector-app "gamma"))
      "codex_cli"))
  (("gamma")))

!(assertEqualToResult
  (codex-test-connector-app-ids
    (codex:connectors-filter-disallowed-connectors
      ((codex-test-connector-app "asdk_app_6938a94a61d881918ef32cb999ff937c")
       (codex-test-connector-app "connector_3f8d1a79f27c4c7ba1a897ab13bf37dc")
       (codex-test-connector-app "delta"))
      "codex_cli"))
  (("delta")))

!(assertEqualToResult
  (codex-test-connector-app-ids
    (codex:connectors-filter-disallowed-connectors
      ((codex-test-connector-app "connector_openai_foo")
       (codex-test-connector-app "asdk_app_6938a94a61d881918ef32cb999ff937c")
       (codex-test-connector-app "connector_0f9c9d4592e54d0a9a12b3f44a1e2010"))
      "codex_atlas"))
  (("asdk_app_6938a94a61d881918ef32cb999ff937c")))
