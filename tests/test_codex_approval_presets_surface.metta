!(register-module! ../codex)
!(import! &self json)
!(import! &self list)
!(import! &self codex:approval_presets)

!(assertEqual
  (list:len (codex:builtin-approval-presets))
  3)

!(assertEqualToResult
  (let $presets (codex:builtin-approval-presets)
    ((codex:approval-preset-id (list:at $presets 0))
     (codex:approval-preset-id (list:at $presets 1))
     (codex:approval-preset-id (list:at $presets 2))))
  (("read-only" "auto" "full-access")))

!(assertEqualToResult
  (let $presets (codex:builtin-approval-presets)
    ((codex:approval-preset-label (list:at $presets 0))
     (codex:approval-preset-label (list:at $presets 1))
     (codex:approval-preset-label (list:at $presets 2))))
  (("Read Only" "Default" "Full Access")))

!(assertEqual
  (codex:approval-preset-description
    (list:at (codex:builtin-approval-presets) 0))
  "Codex can read files in the current workspace. Approval is required to edit files or access the internet.")

!(assertEqual
  (codex:approval-preset-description
    (list:at (codex:builtin-approval-presets) 1))
  "Codex can read and edit files in the current workspace, and run commands. Approval is required to access the internet or edit other files. (Identical to Agent mode)")

!(assertEqual
  (codex:approval-preset-description
    (list:at (codex:builtin-approval-presets) 2))
  "Codex can edit files outside this workspace and access the internet without asking for approval. Exercise caution when using.")

!(assertEqualToResult
  (let $presets (codex:builtin-approval-presets)
    ((json-stringify
       (codex:session-approval-policy-json
         (codex:approval-preset-approval (list:at $presets 0))))
     (json-stringify
       (codex:session-approval-policy-json
         (codex:approval-preset-approval (list:at $presets 1))))
     (json-stringify
       (codex:session-approval-policy-json
         (codex:approval-preset-approval (list:at $presets 2))))))
  (("\"on-request\"" "\"on-request\"" "\"never\"")))

!(assertEqualToResult
  (let $presets (codex:builtin-approval-presets)
    ((json-stringify
       (codex:session-sandbox-policy-json
         (codex:approval-preset-sandbox (list:at $presets 0))))
     (json-stringify
       (codex:session-sandbox-policy-json
         (codex:approval-preset-sandbox (list:at $presets 1))))
     (json-stringify
       (codex:session-sandbox-policy-json
         (codex:approval-preset-sandbox (list:at $presets 2))))))
  (("{\"type\":\"read-only\"}"
    "{\"type\":\"workspace-write\",\"network_access\":false,\"exclude_tmpdir_env_var\":false,\"exclude_slash_tmp\":false}"
    "{\"type\":\"danger-full-access\"}")))
