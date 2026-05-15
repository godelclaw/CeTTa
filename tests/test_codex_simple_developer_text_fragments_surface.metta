!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context_fragment)

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:personality-spec-instructions
      "Concise, technical, direct"))
  ("<personality_spec> The user has requested a new communication style. Future messages should adhere to the following personality: \nConcise, technical, direct </personality_spec>"))

!(assertEqualToResult
  (codex:personality-spec-instructions-matches-text
    " <PERSONALITY_SPEC> body </personality_spec> ")
  (True))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:image-generation-instructions
      "/tmp/images"
      "/tmp/images/out.png"))
  ("Generated images are saved to /tmp/images as /tmp/images/out.png by default.\nIf you need to use a generated image at another path, copy it and leave the original in place unless the user explicitly asks you to delete it."))

!(assertEqualToResult
  (codex:image-generation-instructions-matches-text
    "Generated images are saved to /tmp/images as /tmp/images/out.png by default.")
  (False))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:model-switch-instructions
      "Continue using the smaller context window guidance."))
  ("<model_switch>\nThe user was previously using a different model. Please continue the conversation according to the following instructions:\n\nContinue using the smaller context window guidance.\n</model_switch>"))

!(assertEqualToResult
  (codex:model-switch-instructions-matches-text
    " <MODEL_SWITCH>\nbody\n</model_switch> ")
  (True))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:guardian-followup-review-reminder))
  ("Use prior reviews as context, not binding precedent. Follow the Workspace Policy. If the user explicitly approves a previously rejected action after being informed of the concrete risks, set outcome to \"allow\" unless the policy explicitly disallows user overwrites in such cases."))

!(assertEqualToResult
  (codex:guardian-followup-review-reminder-matches-text
    "Use prior reviews as context, not binding precedent.")
  (False))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:hook-additional-context
      "extra hook context"))
  ("extra hook context"))

!(assertEqualToResult
  (codex:hook-additional-context-matches-text
    "extra hook context")
  (False))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:approved-command-prefix-saved
      "git status\npytest"))
  ("Approved command prefix saved:\ngit status\npytest"))

!(assertEqualToResult
  (codex:approved-command-prefix-saved-matches-text
    "Approved command prefix saved:\ngit status")
  (False))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:network-rule-saved-from-amendment
      (codex:network-policy-amendment
        (codex:network-policy-rule-action-allow)
        "api.example.com")))
  ("Allowed network rule saved in execpolicy (allowlist): api.example.com"))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:network-rule-saved-from-amendment
      (codex:network-policy-amendment
        (codex:network-policy-rule-action-deny)
        "blocked.example.com")))
  ("Denied network rule saved in execpolicy (denylist): blocked.example.com"))

!(assertEqualToResult
  (codex:network-rule-saved-matches-text
    "Allowed network rule saved in execpolicy (allowlist): api.example.com")
  (False))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:contextual-fragment-response-item
        (codex:model-switch-instructions
          "Continue using the smaller context window guidance."))))
  ("{\"type\":\"message\",\"role\":\"developer\",\"content\":[{\"type\":\"input_text\",\"text\":\"<model_switch>\\nThe user was previously using a different model. Please continue the conversation according to the following instructions:\\n\\nContinue using the smaller context window guidance.\\n</model_switch>\"}]}"))
