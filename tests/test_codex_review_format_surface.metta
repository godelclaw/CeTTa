!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:review_format)

!(assertEqual
  (codex:format-review-findings-block
    ((codex:review-finding
        "Null path handling"
        "First line\r\nSecond line\r\n"
        0.75
        1
        (codex:review-code-location
          "/tmp/a.rs"
          (codex:review-line-range 12 14)))))
  "\nReview comment:\n\n- Null path handling — /tmp/a.rs:12-14\n  First line\n  Second line")

!(assertEqual
  (codex:format-review-findings-block
    ((codex:review-finding
        "Missing check"
        "Body one"
        0.5
        2
        (codex:review-code-location
          "/tmp/one.rs"
          (codex:review-line-range 1 2)))
     (codex:review-finding
        "Still selected"
        "Body two"
        0.9
        1
        (codex:review-code-location
          "/tmp/two.rs"
          (codex:review-line-range 3 3))))
    (False))
  "\nFull review comments:\n\n- [ ] Missing check — /tmp/one.rs:1-2\n  Body one\n\n- [x] Still selected — /tmp/two.rs:3-3\n  Body two")

!(assertEqual
  (codex:render-review-output-text
    (codex:review-output-event
      ((codex:review-finding
          "Leaked temp file"
          "Cleanup is skipped on the error path."
          0.8
          1
          (codex:review-code-location
            "/tmp/review.rs"
            (codex:review-line-range 20 24))))
      "incorrect"
      "  The patch is not safe to merge.  "
      0.6))
  "The patch is not safe to merge.\n\nReview comment:\n\n- Leaked temp file — /tmp/review.rs:20-24\n  Cleanup is skipped on the error path.")

!(assertEqual
  (codex:render-review-output-text
    (codex:default-review-output-event))
  "Reviewer failed to output a response.")
