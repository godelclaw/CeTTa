!(register-module! ../codex)
!(import! &self fs)
!(import! &self json)
!(import! &self process)
!(import! &self str)
!(import! &self codex:protocol)
!(import! &self codex:tool_router_bridge)

(= (codex-tool-router-bridge-list-dir-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-list-dir")

(= (codex-tool-router-bridge-view-image-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-view-image")

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-list-dir /home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-view-image && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-list-dir/nested/deeper /home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-view-image && printf 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6x0AAAAASUVORK5CYII=' | base64 -d > /home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-view-image/pixel.png"))
  (0))

!(fs-write-text
  "/home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-list-dir/entry.txt"
  "content")
!(fs-write-text
  "/home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-list-dir/nested/child.txt"
  "child")
!(fs-write-text
  "/home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-list-dir/nested/deeper/grandchild.txt"
  "grandchild")

!(assertEqualToResult
  (str-starts-with?
    (codex:tool-result-output-text
      (once
        (codex:bridge-run-list-dir-tool-call-item
          "call-bridge-list-dir"
          "{\"dir_path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-list-dir\",\"offset\":1,\"limit\":5,\"depth\":2}")))
    "Absolute path: /home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-list-dir\nentry.txt\nnested/\n  child.txt\n  deeper/")
  (True))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (once
        (codex:bridge-run-view-image-tool-call-item
          "call-bridge-view-image"
          "{\"path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-tool-router-bridge-view-image/pixel.png\"}"))))
  ("{\"type\":\"custom_tool_call_output\",\"call_id\":\"call-bridge-view-image\",\"output\":[{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6x0AAAAASUVORK5CYII=\",\"detail\":\"high\"}]}"))
