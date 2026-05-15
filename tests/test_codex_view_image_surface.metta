!(register-module! ../codex)
!(import! &self json)
!(import! &self fs)
!(import! &self process)
!(import! &self codex:protocol)
!(import! &self codex:view_image)

(= (codex-view-image-fixture-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture")

(= (codex-view-image-pixel-path)
   "/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/pixel.png")

(= (codex-view-image-note-path)
   "/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/note.txt")

(= (codex-view-image-dir-path)
   "/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/subdir")

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/subdir && printf 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6x0AAAAASUVORK5CYII=' | base64 -d > /home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/pixel.png"))
  (0))

!(fs-write-text (codex-view-image-note-path) "not an image")

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (once
        (codex:run-view-image-tool-call
          "call-view-image"
          "{\"path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/pixel.png\"}"))))
  ("{\"type\":\"custom_tool_call_output\",\"call_id\":\"call-view-image\",\"output\":[{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6x0AAAAASUVORK5CYII=\",\"detail\":\"high\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (once
        (codex:run-view-image-tool-call-with-context
          (codex:view-image-handler-context
            True
            True
            True
            "/home/zarclaw/repos/CeTTa")
          "call-view-image-original"
          "{\"path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/pixel.png\",\"detail\":\"original\"}"))))
  ("{\"type\":\"custom_tool_call_output\",\"call_id\":\"call-view-image-original\",\"output\":[{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6x0AAAAASUVORK5CYII=\",\"detail\":\"original\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (once
        (codex:run-view-image-tool-call-with-context
          (codex:view-image-handler-context
            True
            True
            False
            (codex-view-image-fixture-root))
          "call-view-image-relative"
          "{\"path\":\"pixel.png\"}"))))
  ("{\"type\":\"custom_tool_call_output\",\"call_id\":\"call-view-image-relative\",\"output\":[{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6x0AAAAASUVORK5CYII=\",\"detail\":\"high\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (once
        (codex:run-view-image-tool-call-with-context
          (codex:view-image-handler-context
            True
            True
            False
            (codex-view-image-fixture-root))
          "call-view-image-original-fallback"
          "{\"path\":\"pixel.png\",\"detail\":\"original\"}"))))
  ("{\"type\":\"custom_tool_call_output\",\"call_id\":\"call-view-image-original-fallback\",\"output\":[{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6x0AAAAASUVORK5CYII=\",\"detail\":\"high\"}]}"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-view-image-tool-call
        "call-view-image-detail-error"
        "{\"path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/pixel.png\",\"detail\":\"high\"}")))
  ("view_image.detail only supports `original`; omit `detail` for default resized behavior, got `high`"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-view-image-tool-call-with-context
        (codex:view-image-handler-context
          False
          True
          False
          "/home/zarclaw/repos/CeTTa")
        "call-view-image-unsupported"
        "{\"path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/pixel.png\"}")))
  ("view_image is not allowed because you do not support image inputs"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-view-image-tool-call-with-context
        (codex:view-image-handler-context
          True
          False
          False
          "/home/zarclaw/repos/CeTTa")
        "call-view-image-unavailable"
        "{\"path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/pixel.png\"}")))
  ("view_image is unavailable in this session"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-view-image-tool-call
        "call-view-image-not-file"
        "{\"path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/subdir\"}")))
  ("image path `/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/subdir` is not a file"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-view-image-tool-call
        "call-view-image-missing"
        "{\"path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/missing.png\"}")))
  ("unable to locate image at `/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/missing.png`: No such file or directory"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-view-image-tool-call
        "call-view-image-process"
        "{\"path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/note.txt\"}")))
  ("unable to process image at `/home/zarclaw/repos/CeTTa/runtime/codex-view-image-fixture/note.txt`: unsupported image format"))
