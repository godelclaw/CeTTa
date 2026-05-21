!(register-module! ../codex)
!(import! &self json)
!(import! &self str)
!(import! &self codex:js_repl)

(= (test-js-repl-string-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (test-js-repl-json-field $object $key)
   (json-object-get $object $key))

!(assertEqual
  (codex:js-repl-tool-name)
  "js_repl")

!(assertEqual
  (codex:js-repl-reset-tool-name)
  "js_repl_reset")

!(assertEqual
  (test-js-repl-json-field
    (codex:js-repl-tool-json)
    "type")
  (JsonString "custom"))

!(assertEqualToResult
  (case (json-object-get (codex:js-repl-tool-json) "format")
    (((JsonObject $pairs)
      (json-object-get (JsonObject $pairs) "syntax"))))
  ((JsonString "lark")))

!(assertEqual
  (test-js-repl-string-contains
    (codex:js-repl-freeform-grammar)
    "PRAGMA_LINE")
  True)

!(assertEqual
  (test-js-repl-string-contains
    (codex:js-repl-freeform-grammar)
    "`[^`]")
  True)

!(assertEqual
  (test-js-repl-string-contains
    (codex:js-repl-freeform-grammar)
    "``[^`]")
  True)

!(assertEqual
  (test-js-repl-string-contains
    (codex:js-repl-freeform-grammar)
    "PLAIN_JS_SOURCE")
  True)

!(assertEqual
  (test-js-repl-string-contains
    (codex:js-repl-freeform-grammar)
    "codex-js-repl:")
  True)

!(assertEqual
  (test-js-repl-string-contains
    (codex:js-repl-freeform-grammar)
    "(?!")
  False)

!(assertEqualToResult
  (json-stringify (codex:js-repl-reset-tool-json))
  ("{\"type\":\"function\",\"name\":\"js_repl_reset\",\"description\":\"Restarts the js_repl kernel for this run and clears persisted top-level bindings.\",\"strict\":false,\"parameters\":{\"type\":\"object\",\"properties\":{},\"additionalProperties\":false}}"))

!(assertEqual
  (codex:parse-js-repl-freeform-args "console.log('ok');")
  (CodexJsReplParseOk
    (CodexJsReplArgs "console.log('ok');" CodexAbsent)))

!(assertEqual
  (codex:parse-js-repl-freeform-args
    "// codex-js-repl: timeout_ms=15000\nconsole.log('ok');")
  (CodexJsReplParseOk
    (CodexJsReplArgs "console.log('ok');" 15000)))

!(assertEqual
  (codex:parse-js-repl-freeform-args
    "   // codex-js-repl: timeout_ms=15000\nconsole.log('ok');")
  (CodexJsReplParseOk
    (CodexJsReplArgs "console.log('ok');" 15000)))

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args
      "// codex-js-repl: nope=1\nconsole.log('ok');"))
  "js_repl pragma only supports timeout_ms; got `nope`")

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args
      "// codex-js-repl: reset=true\nconsole.log('ok');"))
  "js_repl pragma only supports timeout_ms; got `reset`")

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args
      "// codex-js-repl: timeout_ms=1 timeout_ms=2\nconsole.log('ok');"))
  "js_repl pragma specifies timeout_ms more than once")

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args
      "// codex-js-repl: timeout_ms=soon\nconsole.log('ok');"))
  "js_repl pragma timeout_ms must be an integer; got `soon`")

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args
      "// codex-js-repl: timeout_ms\nconsole.log('ok');"))
  "js_repl pragma expects space-separated key=value pairs (supported keys: timeout_ms); got `timeout_ms`")

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args
      "// codex-js-repl: timeout_ms=15000\n   "))
  "js_repl pragma must be followed by JavaScript source on subsequent lines")

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args "   "))
  (codex:js-repl-empty-input-message))

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args "{\"code\":\"await doThing()\"}"))
  (codex:js-repl-common-wrapped-source-message))

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args "\"console.log(1)\""))
  (codex:js-repl-common-wrapped-source-message))

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-freeform-args "```js\nconsole.log(1)\n```"))
  (codex:js-repl-markdown-fence-message))

!(assertEqual
  (codex:parse-js-repl-freeform-args "[\"array\", \"is\", \"accepted\"]")
  (CodexJsReplParseOk
    (CodexJsReplArgs "[\"array\", \"is\", \"accepted\"]" CodexAbsent)))

!(assertEqual
  (codex:js-repl-join-outputs "stdout" "stderr")
  "stdout\nstderr")

!(assertEqual
  (codex:js-repl-join-outputs "" "stderr")
  "stderr")

!(assertEqual
  (codex:build-js-repl-exec-output "hello" CodexAbsent 12)
  (CodexJsReplExecOutput 0 "hello" "" "hello" 12 False))

!(assertEqual
  (codex:build-js-repl-exec-output "" "boom" 12)
  (CodexJsReplExecOutput 1 "" "boom" "boom" 12 False))
