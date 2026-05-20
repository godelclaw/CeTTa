!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context)
!(import! &self codex:tools)

(= (codex-tools-hook-apply-patch-sample)
   "*** Begin Patch\n*** Add File: hello.txt\n+hello\n*** End Patch")

(= (codex-tools-hook-apply-patch-function-json)
   "{\"input\":\"*** Begin Patch\\n*** Add File: hello.txt\\n+hello\\n*** End Patch\"}")

!(assertEqual
  (codex:apply-patch-payload-command
    (codex:function-payload
      (codex-tools-hook-apply-patch-function-json)))
  (codex-tools-hook-apply-patch-sample))

!(assertEqual
  (codex:apply-patch-payload-command
    (codex:custom-payload
      (codex-tools-hook-apply-patch-sample)))
  (codex-tools-hook-apply-patch-sample))

!(assertEqual
  (codex:apply-patch-payload-command
    (codex:function-payload "{}"))
  Empty)

!(assertEqual
  (codex:apply-patch-payload-command
    (codex:function-payload "{"))
  Empty)

!(assertEqualToResult
  (json-stringify
    (codex:pre-tool-use-payload-json
      (codex:apply-patch-pre-tool-use-payload
        (codex:function-payload
          (codex-tools-hook-apply-patch-function-json)))))
  ("{\"tool_name\":{\"name\":\"apply_patch\",\"matcher_aliases\":[\"Write\",\"Edit\"]},\"tool_input\":{\"command\":\"*** Begin Patch\\n*** Add File: hello.txt\\n+hello\\n*** End Patch\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:pre-tool-use-payload-json
      (codex:apply-patch-pre-tool-use-payload
        (codex:custom-payload
          (codex-tools-hook-apply-patch-sample)))))
  ("{\"tool_name\":{\"name\":\"apply_patch\",\"matcher_aliases\":[\"Write\",\"Edit\"]},\"tool_input\":{\"command\":\"*** Begin Patch\\n*** Add File: hello.txt\\n+hello\\n*** End Patch\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:post-tool-use-payload-json
      (codex:apply-patch-post-tool-use-payload
        "call-apply-patch"
        (codex:custom-payload
          (codex-tools-hook-apply-patch-sample))
        (codex:apply-patch-tool-output-from-text
          "Success. Updated files."))))
  ("{\"tool_name\":{\"name\":\"apply_patch\",\"matcher_aliases\":[\"Write\",\"Edit\"]},\"tool_use_id\":\"call-apply-patch\",\"tool_input\":{\"command\":\"*** Begin Patch\\n*** Add File: hello.txt\\n+hello\\n*** End Patch\"},\"tool_response\":\"Success. Updated files.\"}"))

!(assertEqual
  (codex:apply-patch-pre-tool-use-payload
    (codex:local-shell-payload ("apply_patch")))
  Empty)

!(assertEqual
  (codex:apply-patch-post-tool-use-payload
    "call-unsupported"
    (codex:local-shell-payload ("apply_patch"))
    (codex:apply-patch-tool-output-from-text "ignored"))
  Empty)
