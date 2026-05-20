!(register-module! ../codex)
!(import! &self codex:installation_id)

(= (installation-id-lower)
   "67e55044-10b1-426f-9247-bb680e5fe0c8")

(= (installation-id-upper)
   "67E55044-10B1-426F-9247-BB680E5FE0C8")

(= (installation-id-simple-upper)
   "67E5504410B1426F9247BB680E5FE0C8")

(= (installation-id-generated)
   "018f4d4a-0000-7000-8000-000000000001")

!(assertEqualToResult
  (codex:installation-id-filename)
  ("installation_id"))

!(assertEqualToResult
  (codex:installation-id-parse-existing "")
  (CodexAbsent))

!(assertEqualToResult
  (codex:installation-id-parse-existing "  \n\t")
  (CodexAbsent))

!(assertEqualToResult
  (codex:installation-id-parse-existing (installation-id-lower))
  ("67e55044-10b1-426f-9247-bb680e5fe0c8"))

!(assertEqualToResult
  (codex:installation-id-parse-existing (installation-id-upper))
  ("67e55044-10b1-426f-9247-bb680e5fe0c8"))

!(assertEqualToResult
  (codex:installation-id-parse-existing (installation-id-simple-upper))
  ("67e55044-10b1-426f-9247-bb680e5fe0c8"))

!(assertEqualToResult
  (codex:installation-id-parse-existing
    "{67E55044-10B1-426F-9247-BB680E5FE0C8}")
  ("67e55044-10b1-426f-9247-bb680e5fe0c8"))

!(assertEqualToResult
  (codex:installation-id-parse-existing
    "urn:uuid:67E55044-10B1-426F-9247-BB680E5FE0C8")
  ("67e55044-10b1-426f-9247-bb680e5fe0c8"))

!(assertEqualToResult
  (codex:installation-id-parse-existing
    "URN:UUID:67E55044-10B1-426F-9247-BB680E5FE0C8")
  (CodexAbsent))

!(assertEqualToResult
  (codex:installation-id-parse-existing "not-a-uuid")
  (CodexAbsent))

!(assertEqualToResult
  (codex:installation-id-parse-existing
    "67e55044-10b1-426f-9247-bb680e5fe0cg")
  (CodexAbsent))

!(assertEqualToResult
  (codex:installation-id-resolution-action
    (codex:resolve-installation-id-from-contents
      (installation-id-upper)
      (installation-id-generated)))
  ("reuse"))

!(assertEqualToResult
  (codex:installation-id-resolution-id
    (codex:resolve-installation-id-from-contents
      (installation-id-upper)
      (installation-id-generated)))
  ("67e55044-10b1-426f-9247-bb680e5fe0c8"))

!(assertEqualToResult
  (codex:installation-id-resolution-should-write
    (codex:resolve-installation-id-from-contents
      (installation-id-upper)
      (installation-id-generated)))
  (False))

!(assertEqualToResult
  (codex:installation-id-resolution-action
    (codex:resolve-installation-id-from-contents
      "not-a-uuid"
      (installation-id-generated)))
  ("write"))

!(assertEqualToResult
  (codex:installation-id-resolution-id
    (codex:resolve-installation-id-from-contents
      "not-a-uuid"
      (installation-id-generated)))
  ("018f4d4a-0000-7000-8000-000000000001"))

!(assertEqualToResult
  (codex:installation-id-resolution-should-write
    (codex:resolve-installation-id-from-contents
      "not-a-uuid"
      (installation-id-generated)))
  (True))
