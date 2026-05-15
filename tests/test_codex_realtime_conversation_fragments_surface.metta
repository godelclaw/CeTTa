!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context_fragment)

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:realtime-start-instructions))
  ("<realtime_conversation>\nRealtime conversation started.\n\nYou are operating as a backend executor behind an intermediary. The user does not talk to you directly. Any response you produce will be consumed by the intermediary and may be summarized before the user sees it.\n\nWhen invoked, you receive the latest conversation transcript and any relevant mode or metadata. The intermediary may invoke you even when backend help is not actually needed. Use the transcript to decide whether you should do work. If backend help is unnecessary, avoid verbose responses that add user-visible latency.\n\nWhen user text is routed from realtime, treat it as a transcript. It may be unpunctuated or contain recognition errors.\n\n- Keep responses concise and action-oriented. Your updates should help the intermediary respond to the user.\n</realtime_conversation>"))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:realtime-start-with-instructions
      "Realtime conversation started.\n\nCustom instructions."))
  ("<realtime_conversation>\nRealtime conversation started.\n\nCustom instructions.\n</realtime_conversation>"))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:realtime-end-instructions
      "user requested stop"))
  ("<realtime_conversation>\nRealtime conversation ended.\n\nSubsequent user input will return to typed text rather than transcript-style text. Do not assume recognition errors or missing punctuation once realtime has ended. Resume normal chat behavior.\n\nReason: user requested stop\n</realtime_conversation>"))

!(assertEqualToResult
  (codex:realtime-conversation-matches-text
    " <REALTIME_CONVERSATION>\nbody\n</realtime_conversation> ")
  (True))

!(assertEqualToResult
  (codex:contextual-fragment-role
    (codex:realtime-end-instructions
      "user requested stop"))
  ("developer"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:contextual-fragment-response-item
        (codex:realtime-start-with-instructions
          "Realtime conversation started.\n\nCustom instructions."))))
  ("{\"type\":\"message\",\"role\":\"developer\",\"content\":[{\"type\":\"input_text\",\"text\":\"<realtime_conversation>\\nRealtime conversation started.\\n\\nCustom instructions.\\n</realtime_conversation>\"}]}"))
