!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:apply_patch)
!(import! &self codex:protocol)

(= (codex-apply-protocol-action)
   (CodexApplyPatchAction
     "/home/zarclaw/repos/CeTTa"
     ((CodexApplyPatchFileChangeAdd
        "runtime/codex-apply-protocol-new.txt"
        "new\n")
      (CodexApplyPatchFileChangeUpdate
        "runtime/codex-apply-protocol-old.txt"
        "@@\n-old\n+updated\n"
        "runtime/codex-apply-protocol-moved.txt"
        "updated\n")
      (CodexApplyPatchFileChangeDelete
        "runtime/codex-apply-protocol-delete.txt"
        "delete me\n"))))

!(assertEqualToResult
  (let $action (codex-apply-protocol-action)
    (json-stringify
      (codex:file-change-map-json
        (codex:convert-apply-patch-to-protocol $action))))
  ("{\"runtime/codex-apply-protocol-new.txt\":{\"type\":\"add\",\"content\":\"new\\n\"},\"runtime/codex-apply-protocol-old.txt\":{\"type\":\"update\",\"unified_diff\":\"@@\\n-old\\n+updated\\n\",\"move_path\":\"runtime/codex-apply-protocol-moved.txt\"},\"runtime/codex-apply-protocol-delete.txt\":{\"type\":\"delete\",\"content\":\"delete me\\n\"}}"))
