!(import! &self list)
!(import! &self patch)

!(let $inspection
    (patch-inspect-streaming
      "*** Begin Patch\n*** Add File: src/hello.txt\n+hello\n+wor")
  (let $changes (patch-action-changes (patch-inspect-action $inspection))
    (assertEqualToResult
      (patch-action-change-content (list:first $changes))
      ("hello\nwor\n"))))

!(let $inspection
    (patch-inspect-streaming
      "*** Begin Patch\n*** Update File: src/old.rs\n*** Move to: src/new.rs\n@@\n-old\n+new")
  (let $changes (patch-action-changes (patch-inspect-action $inspection))
    (assertEqualToResult
      (patch-action-change-unified-diff (list:first $changes))
      ("@@\n-old\n+new\n"))))

!(let $inspection
    (patch-inspect-streaming
      "*** Begin Patch\n*** Update File: src/old.rs\n*** Move to: src/new.rs\n@@\n-old\n+new")
  (let $changes (patch-action-changes (patch-inspect-action $inspection))
    (assertEqualToResult
      (patch-action-change-move-path (list:first $changes))
      ("src/new.rs"))))

!(assertEqualToResult
  (patch-inspect-ok?
    (patch-inspect-streaming
      "*** Begin Patch\n*** Delete File: gone.txt"))
  (True))

!(assertEqualToResult
  (patch-inspect-ok?
    (patch-inspect
      "/home/zarclaw/repos/CeTTa"
      "*** Begin Patch\n*** Delete File: gone.txt"))
  (False))

!(assertEqualToResult
  (patch-action-changes
    (patch-inspect-action
      (patch-inspect-streaming
        "*** Begin Patch\n")))
  (()))
