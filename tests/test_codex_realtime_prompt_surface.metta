!(register-module! ../codex)
!(import! &self str)
!(import! &self codex:realtime_prompt)

(= (codex-realtime-prompt-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

!(assertEqual
  (codex:prepare-realtime-backend-prompt
    (codex:realtime-request-prompt "prompt from request")
    "prompt from config"
    "Ada")
  "prompt from config")

!(assertEqual
  (codex:prepare-realtime-backend-prompt
    (codex:realtime-request-prompt "prompt from request")
    "  prompt from config  "
    "Ada")
  "  prompt from config  ")

!(assertEqual
  (codex:prepare-realtime-backend-prompt
    (codex:realtime-request-prompt "prompt from request")
    "   "
    "Ada")
  "prompt from request")

!(assertEqual
  (codex:prepare-realtime-backend-prompt
    (codex:realtime-request-prompt "prompt from request")
    CodexAbsent
    "Ada")
  "prompt from request")

!(assertEqual
  (codex:prepare-realtime-backend-prompt
    (codex:realtime-request-prompt "")
    CodexAbsent
    "Ada")
  "")

!(assertEqual
  (codex:prepare-realtime-backend-prompt
    (codex:realtime-request-prompt-none)
    CodexAbsent
    "Ada")
  "")

!(assertEqual
  (str-starts-with?
    (codex:prepare-realtime-backend-prompt CodexAbsent CodexAbsent "Grace")
    "## Identity, tone, and role")
  True)

!(assertEqual
  (codex-realtime-prompt-contains
    (codex:prepare-realtime-backend-prompt CodexAbsent CodexAbsent "Grace")
    "You are Codex, an OpenAI general-purpose agentic assistant")
  True)

!(assertEqual
  (codex-realtime-prompt-contains
    (codex:prepare-realtime-backend-prompt CodexAbsent CodexAbsent "Grace")
    "The user's name is Grace.")
  True)

!(assertEqual
  (codex-realtime-prompt-contains
    (codex:prepare-realtime-backend-prompt CodexAbsent CodexAbsent "Grace")
    "{{ user_first_name }}")
  False)

!(assertEqual
  (str-ends-with?
    (codex:prepare-realtime-backend-prompt CodexAbsent CodexAbsent "Grace")
    "\n")
  False)

!(assertEqual
  (codex:realtime-current-user-first-name "Ada Lovelace" "ignored")
  "Ada")

!(assertEqual
  (codex:realtime-current-user-first-name "   " "grace hopper")
  "grace")

!(assertEqual
  (codex:realtime-current-user-first-name CodexAbsent "  linus  torvalds ")
  "linus")

!(assertEqual
  (codex:realtime-current-user-first-name "" "")
  "there")

!(assertEqual
  (codex:prepare-realtime-backend-prompt-from-user-names
    CodexAbsent
    CodexAbsent
    "Ada Lovelace"
    "ignored")
  (codex:prepare-realtime-backend-prompt
    CodexAbsent
    CodexAbsent
    "Ada"))
