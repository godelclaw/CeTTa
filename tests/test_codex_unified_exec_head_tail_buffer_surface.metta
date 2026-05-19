!(register-module! ../codex)
!(import! &self codex:unified_exec_head_tail_buffer)

!(assertEqual
  (codex:head-tail-buffer-head-budget
    (codex:head-tail-buffer-new 10))
  5)

!(assertEqual
  (codex:head-tail-buffer-tail-budget
    (codex:head-tail-buffer-new 11))
  6)

!(assertEqual
  (codex:head-tail-buffer-max-bytes
    (codex:head-tail-buffer-default))
  (codex:unified-exec-output-max-bytes))

!(assertEqual
  (codex:head-tail-buffer-head-budget
    (codex:head-tail-buffer-default))
  524288)

!(assertEqual
  (codex:head-tail-buffer-tail-budget
    (codex:head-tail-buffer-default))
  524288)

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "0123456789")
      (codex:head-tail-buffer-omitted-bytes $buf-1)))
  0)

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "0123456789")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "ab")
        (codex:head-tail-buffer-to-bytes $buf-2))))
  "01234789ab")

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "0123456789")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "ab")
        (codex:head-tail-buffer-omitted-bytes $buf-2))))
  2)

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 0)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "abc")
      (codex:head-tail-buffer-retained-bytes $buf-1)))
  0)

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 0)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "abc")
      (codex:head-tail-buffer-omitted-bytes $buf-1)))
  3)

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 0)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "abc")
      (codex:head-tail-buffer-to-bytes $buf-1)))
  "")

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 0)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "abc")
      (codex:head-tail-buffer-snapshot-chunks $buf-1)))
  ())

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 1)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "abc")
      (codex:head-tail-buffer-retained-bytes $buf-1)))
  1)

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 1)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "abc")
      (codex:head-tail-buffer-omitted-bytes $buf-1)))
  2)

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 1)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "abc")
      (codex:head-tail-buffer-to-bytes $buf-1)))
  "c")

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "0123456789")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "ab")
        (let $drained (codex:head-tail-buffer-drain-chunks $buf-2)
          (codex:head-tail-buffer-drain-result-chunks $drained)))))
  ("01234" "789" "ab"))

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "0123456789")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "ab")
        (let $drained (codex:head-tail-buffer-drain-chunks $buf-2)
          (codex:head-tail-buffer-retained-bytes
            (codex:head-tail-buffer-drain-result-buffer $drained))))))
  0)

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "0123456789")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "ab")
        (let $drained (codex:head-tail-buffer-drain-chunks $buf-2)
          (codex:head-tail-buffer-omitted-bytes
            (codex:head-tail-buffer-drain-result-buffer $drained))))))
  0)

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "0123456789")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "ABCDEFGHIJK")
        (codex:head-tail-buffer-to-bytes $buf-2))))
  "01234GHIJK")

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "01")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "234")
        (codex:head-tail-buffer-to-bytes $buf-2))))
  "01234")

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "01")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "234")
        (let $buf-3 (codex:head-tail-buffer-push-chunk $buf-2 "567")
          (let $buf-4 (codex:head-tail-buffer-push-chunk $buf-3 "89")
            (codex:head-tail-buffer-to-bytes $buf-4))))))
  "0123456789")

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "01")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "234")
        (let $buf-3 (codex:head-tail-buffer-push-chunk $buf-2 "567")
          (let $buf-4 (codex:head-tail-buffer-push-chunk $buf-3 "89")
            (let $buf-5 (codex:head-tail-buffer-push-chunk $buf-4 "a")
              (codex:head-tail-buffer-to-bytes $buf-5)))))))
  "012346789a")

!(assertEqual
  (let $buf-0 (codex:head-tail-buffer-new 10)
    (let $buf-1 (codex:head-tail-buffer-push-chunk $buf-0 "01")
      (let $buf-2 (codex:head-tail-buffer-push-chunk $buf-1 "234")
        (let $buf-3 (codex:head-tail-buffer-push-chunk $buf-2 "567")
          (let $buf-4 (codex:head-tail-buffer-push-chunk $buf-3 "89")
            (let $buf-5 (codex:head-tail-buffer-push-chunk $buf-4 "a")
              (codex:head-tail-buffer-omitted-bytes $buf-5)))))))
  1)
