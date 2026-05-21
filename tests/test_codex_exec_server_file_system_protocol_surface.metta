!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_file_system_protocol)

(= (test:permissions-json)
   (JsonObject
     ((JsonPair "type" (JsonString "managed"))
      (JsonPair
        "file_system"
        (JsonObject ((JsonPair "type" (JsonString "unrestricted")))))
      (JsonPair "network" (JsonString "enabled")))))

(= (test:sandbox)
   (codex:exec-server-fs-sandbox-context
     (test:permissions-json)
     "/repo"
     (codex:exec-server-fs-windows-sandbox-level-restricted-token)
     True
     False))

!(assertEqual
  (codex:exec-server-fs-read-file-method)
  "fs/readFile")

!(assertEqual
  (codex:exec-server-fs-copy-method)
  "fs/copy")

!(assertEqual
  (codex:exec-server-create-directory-options-recursive
    (codex:exec-server-create-directory-options True))
  True)

!(assertEqual
  (codex:exec-server-remove-options-force
    (codex:exec-server-remove-options False True))
  True)

!(assertEqual
  (codex:exec-server-copy-options-recursive
    (codex:exec-server-copy-options True))
  True)

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-sandbox-context-json (test:sandbox)))
  ("{\"permissions\":{\"type\":\"managed\",\"file_system\":{\"type\":\"unrestricted\"},\"network\":\"enabled\"},\"cwd\":\"/repo\",\"windowsSandboxLevel\":\"restricted-token\",\"windowsSandboxPrivateDesktop\":true,\"useLegacyLandlock\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-sandbox-context-json
      (codex:exec-server-fs-sandbox-context
        (test:permissions-json)
        CodexAbsent
        (codex:exec-server-fs-windows-sandbox-level-disabled)
        False
        False)))
  ("{\"permissions\":{\"type\":\"managed\",\"file_system\":{\"type\":\"unrestricted\"},\"network\":\"enabled\"},\"windowsSandboxLevel\":\"disabled\",\"windowsSandboxPrivateDesktop\":false,\"useLegacyLandlock\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-read-file-params-json
      (codex:exec-server-fs-read-file-params
        "/repo/file.txt"
        CodexAbsent)))
  ("{\"path\":\"/repo/file.txt\",\"sandbox\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-read-file-params-json
      (codex:exec-server-fs-read-file-params
        "/repo/file.txt"
        (test:sandbox))))
  ("{\"path\":\"/repo/file.txt\",\"sandbox\":{\"permissions\":{\"type\":\"managed\",\"file_system\":{\"type\":\"unrestricted\"},\"network\":\"enabled\"},\"cwd\":\"/repo\",\"windowsSandboxLevel\":\"restricted-token\",\"windowsSandboxPrivateDesktop\":true,\"useLegacyLandlock\":false}}"))

!(assertEqual
  (codex:exec-server-fs-read-file-response-data-base64
    (codex:exec-server-fs-read-file-response "aGk="))
  "aGk=")

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-read-file-response-json
      (codex:exec-server-fs-read-file-response "aGk=")))
  ("{\"dataBase64\":\"aGk=\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-write-file-params-json
      (codex:exec-server-fs-write-file-params
        "/repo/file.txt"
        "aGk="
        CodexAbsent)))
  ("{\"path\":\"/repo/file.txt\",\"dataBase64\":\"aGk=\",\"sandbox\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-write-file-response-json
      (codex:exec-server-fs-write-file-response)))
  ("{}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-create-directory-params-json
      (codex:exec-server-fs-create-directory-params
        "/repo/new"
        CodexAbsent
        CodexAbsent)))
  ("{\"path\":\"/repo/new\",\"recursive\":null,\"sandbox\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-create-directory-params-json
      (codex:exec-server-fs-create-directory-params
        "/repo/new"
        True
        (test:sandbox))))
  ("{\"path\":\"/repo/new\",\"recursive\":true,\"sandbox\":{\"permissions\":{\"type\":\"managed\",\"file_system\":{\"type\":\"unrestricted\"},\"network\":\"enabled\"},\"cwd\":\"/repo\",\"windowsSandboxLevel\":\"restricted-token\",\"windowsSandboxPrivateDesktop\":true,\"useLegacyLandlock\":false}}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-create-directory-response-json
      (codex:exec-server-fs-create-directory-response)))
  ("{}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-file-metadata-json
      (codex:exec-server-file-metadata
        True
        False
        False
        1000
        2000)))
  ("{\"isDirectory\":true,\"isFile\":false,\"isSymlink\":false,\"createdAtMs\":1000,\"modifiedAtMs\":2000}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-get-metadata-params-json
      (codex:exec-server-fs-get-metadata-params
        "/repo"
        CodexAbsent)))
  ("{\"path\":\"/repo\",\"sandbox\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-get-metadata-response-json
      (codex:exec-server-fs-get-metadata-response
        False
        True
        False
        111
        222)))
  ("{\"isDirectory\":false,\"isFile\":true,\"isSymlink\":false,\"createdAtMs\":111,\"modifiedAtMs\":222}"))

!(assertEqual
  (codex:exec-server-fs-read-directory-entry-file-name
    (codex:exec-server-fs-read-directory-entry "src" True False))
  "src")

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-read-directory-response-json
      (codex:exec-server-fs-read-directory-response
        ((codex:exec-server-fs-read-directory-entry "src" True False)
         (codex:exec-server-fs-read-directory-entry "README.md" False True)))))
  ("{\"entries\":[{\"fileName\":\"src\",\"isDirectory\":true,\"isFile\":false},{\"fileName\":\"README.md\",\"isDirectory\":false,\"isFile\":true}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-read-directory-params-json
      (codex:exec-server-fs-read-directory-params
        "/repo"
        CodexAbsent)))
  ("{\"path\":\"/repo\",\"sandbox\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-remove-params-json
      (codex:exec-server-fs-remove-params
        "/repo/old"
        CodexAbsent
        False
        CodexAbsent)))
  ("{\"path\":\"/repo/old\",\"recursive\":null,\"force\":false,\"sandbox\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-remove-response-json
      (codex:exec-server-fs-remove-response)))
  ("{}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-copy-params-json
      (codex:exec-server-fs-copy-params
        "/repo/a"
        "/repo/b"
        True
        CodexAbsent)))
  ("{\"sourcePath\":\"/repo/a\",\"destinationPath\":\"/repo/b\",\"recursive\":true,\"sandbox\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-copy-response-json
      (codex:exec-server-fs-copy-response)))
  ("{}"))
