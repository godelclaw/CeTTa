!(register-module! ../codex)
!(import! &self codex:apply_patch)
!(import! &self codex:approval)

(= (test:cwd)
   "/repo/project")

(= (test:workspace-policy)
   (codex:patch-fs-policy ((test:cwd)) () ()))

(= (test:add-change $path)
   (CodexApplyPatchFileChangeAdd $path "content\n"))

(= (test:update-change $path $move-path)
   (CodexApplyPatchFileChangeUpdate
     $path
     "@@\n-old\n+new\n"
     $move-path
     "new\n"))

(= (test:action $changes)
   (CodexApplyPatchAction (test:cwd) $changes))

!(assertEqual
  (codex:apply-patch-normalize-path-text
    "/repo/project/./nested/../inner.txt")
  "/repo/project/inner.txt")

!(assertEqual
  (codex:normalized-policy-path
    (test:cwd)
    "../outside.txt")
  "/repo/outside.txt")

!(assertEqual
  (codex:fs-policy-can-write-path-with-cwd
    (test:workspace-policy)
    "../outside.txt"
    (test:cwd))
  False)

!(assertEqual
  (codex:fs-policy-can-write-path-with-cwd
    (test:workspace-policy)
    "nested/../inner.txt"
    (test:cwd))
  True)

!(assertEqual
  (codex:is-write-patch-constrained-to-writable-paths
    (test:action ((test:add-change "../outside.txt")))
    (test:workspace-policy)
    (test:cwd))
  False)

!(assertEqual
  (codex:is-write-patch-constrained-to-writable-paths
    (test:action ((test:update-change "inner.txt" "../moved.txt")))
    (test:workspace-policy)
    (test:cwd))
  False)

!(assertEqual
  (codex:assess-patch-safety
    (test:action ((test:add-change "../outside.txt")))
    (codex:ask-for-approval-granular False)
    (codex:patch-sandbox-workspace-write)
    (test:workspace-policy)
    (test:cwd)
    False)
  (codex:patch-safety-reject
    (codex:patch-rejected-outside-project-reason)))

!(assertEqual
  (codex:assess-patch-safety
    (test:action ((test:add-change "nested/../inner.txt")))
    (codex:ask-for-approval-on-request)
    (codex:patch-sandbox-danger-full-access)
    (test:workspace-policy)
    (test:cwd)
    False)
  (codex:patch-safety-auto-approve "none" False))
