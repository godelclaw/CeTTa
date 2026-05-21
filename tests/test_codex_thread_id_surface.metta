!(register-module! ../codex)
!(import! &self codex:thread_id)

(= (thread-id-lower)
   "67e55044-10b1-426f-9247-bb680e5fe0c8")

(= (thread-id-upper)
   "67E55044-10B1-426F-9247-BB680E5FE0C8")

(= (thread-id-simple-upper)
   "67E5504410B1426F9247BB680E5FE0C8")

!(assertEqualToResult
  (codex:thread-id-from-string (thread-id-lower))
  ((CodexThreadIdOk "67e55044-10b1-426f-9247-bb680e5fe0c8")))

!(assertEqualToResult
  (codex:thread-id-result-type
    (codex:thread-id-from-string (thread-id-lower)))
  ("ok"))

!(assertEqualToResult
  (codex:thread-id-result-value
    (codex:thread-id-from-string (thread-id-lower)))
  ("67e55044-10b1-426f-9247-bb680e5fe0c8"))

!(assertEqualToResult
  (codex:thread-id-from-string (thread-id-upper))
  ((CodexThreadIdOk "67e55044-10b1-426f-9247-bb680e5fe0c8")))

!(assertEqualToResult
  (codex:thread-id-from-string (thread-id-simple-upper))
  ((CodexThreadIdOk "67e55044-10b1-426f-9247-bb680e5fe0c8")))

!(assertEqualToResult
  (codex:thread-id-from-string
    "{67E55044-10B1-426F-9247-BB680E5FE0C8}")
  ((CodexThreadIdOk "67e55044-10b1-426f-9247-bb680e5fe0c8")))

!(assertEqualToResult
  (codex:thread-id-from-string
    "urn:uuid:67E55044-10B1-426F-9247-BB680E5FE0C8")
  ((CodexThreadIdOk "67e55044-10b1-426f-9247-bb680e5fe0c8")))

!(assertEqualToResult
  (codex:thread-id-from-string
    "URN:UUID:67E55044-10B1-426F-9247-BB680E5FE0C8")
  ((CodexThreadIdErr
     "Error(ParseChar { character: 'U', index: 1 })")))

!(assertEqualToResult
  (codex:thread-id-from-string "not-a-uuid")
  ((CodexThreadIdErr
     "Error(ParseChar { character: 'n', index: 1 })")))

!(assertEqualToResult
  (codex:thread-id-result-type
    (codex:thread-id-from-string "not-a-uuid"))
  ("err"))

!(assertEqualToResult
  (codex:thread-id-result-error
    (codex:thread-id-from-string "not-a-uuid"))
  ("Error(ParseChar { character: 'n', index: 1 })"))

!(assertEqualToResult
  (codex:thread-id-from-string "1234")
  ((CodexThreadIdErr
     "Error(ParseSimpleLength { len: 4 })")))

!(assertEqualToResult
  (codex:thread-id-from-string "12345678-1234")
  ((CodexThreadIdErr
     "Error(ParseGroupCount { count: 2 })")))
