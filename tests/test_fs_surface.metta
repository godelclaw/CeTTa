!(import! &self fs)
!(import! &self process)

!(assertEqual (fs-exists? "tests/support/fs_fixture.txt") True)
!(assertEqual (fs-read-text "tests/support/fs_fixture.txt") "first line\nsecond line\n\nthird line\n")
!(assertEqual (fs-read-lines "tests/support/fs_fixture.txt") ("first line" "second line" "" "third line"))
!(assertEqual (fs-write-text "runtime/test_fs_surface_output.txt" "alpha") ())
!(assertEqual (fs-append-text "runtime/test_fs_surface_output.txt" "\nbeta") ())
!(assertEqual (fs-read-text "runtime/test_fs_surface_output.txt") "alpha\nbeta")
!(assertEqual (fs-read-lines "runtime/test_fs_surface_output.txt") ("alpha" "beta"))

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/test-fs-read-dir /home/zarclaw/repos/CeTTa/runtime/test-fs-image && mkdir -p /home/zarclaw/repos/CeTTa/runtime/test-fs-read-dir/sub /home/zarclaw/repos/CeTTa/runtime/test-fs-image && touch /home/zarclaw/repos/CeTTa/runtime/test-fs-read-dir/alpha.txt && printf 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6x0AAAAASUVORK5CYII=' | base64 -d > /home/zarclaw/repos/CeTTa/runtime/test-fs-image/pixel.png"))
  (0))

!(assertEqual
  (fs-read-dir-entries "/home/zarclaw/repos/CeTTa/runtime/test-fs-read-dir")
  (("alpha.txt" "file") ("sub" "directory")))

!(assertEqual
  (fs-path-kind "/home/zarclaw/repos/CeTTa/runtime/test-fs-read-dir")
  "directory")

!(assertEqual
  (fs-path-kind "/home/zarclaw/repos/CeTTa/runtime/test-fs-image/pixel.png")
  "file")

!(assertEqual
  (fs-read-image-data-url "/home/zarclaw/repos/CeTTa/runtime/test-fs-image/pixel.png")
  "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6x0AAAAASUVORK5CYII=")
