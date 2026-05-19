!(register-module! ../codex)
!(import! &self codex:unified_exec_process_pruning)

(= (codex-pruning-meta-10 $id-2-exited $id-3-exited $id-10-exited)
   ((codex:unified-exec-process-meta 1 1 False)
    (codex:unified-exec-process-meta 2 2 $id-2-exited)
    (codex:unified-exec-process-meta 3 3 $id-3-exited)
    (codex:unified-exec-process-meta 4 4 False)
    (codex:unified-exec-process-meta 5 5 False)
    (codex:unified-exec-process-meta 6 6 False)
    (codex:unified-exec-process-meta 7 7 False)
    (codex:unified-exec-process-meta 8 8 False)
    (codex:unified-exec-process-meta 9 9 False)
    (codex:unified-exec-process-meta 10 10 $id-10-exited)))

!(assertEqual
  (codex:max-unified-exec-processes)
  64)

!(assertEqual
  (codex:warning-unified-exec-processes)
  60)

!(assertEqual
  (codex:unified-exec-pruning-protected-recent-count)
  8)

!(assertEqual
  (codex:unified-exec-process-meta-process-id
    (codex:unified-exec-process-meta 12 99 True))
  12)

!(assertEqual
  (codex:unified-exec-process-meta-last-used
    (codex:unified-exec-process-meta 12 99 True))
  99)

!(assertEqual
  (codex:unified-exec-process-meta-has-exited
    (codex:unified-exec-process-meta 12 99 True))
  True)

!(assertEqual
  (codex:unified-exec-process-id-to-prune-from-meta ())
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-process-prune-if-needed-from-meta
    (codex-pruning-meta-10 True False False))
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-process-meta-take-process-ids
    8
    (codex:unified-exec-process-meta-sort-by-last-used-desc
      (codex-pruning-meta-10 True False False)))
  (10 9 8 7 6 5 4 3))

!(assertEqual
  (codex:unified-exec-process-meta-take-process-ids
    10
    (codex:unified-exec-process-meta-sort-by-last-used-asc
      ((codex:unified-exec-process-meta 5 50 False)
       (codex:unified-exec-process-meta 1 10 True)
       (codex:unified-exec-process-meta 3 30 False))))
  (1 3 5))

!(assertEqual
  (codex:unified-exec-process-meta-take-process-ids
    10
    (codex:unified-exec-process-meta-sort-by-last-used-desc
      ((codex:unified-exec-process-meta 5 50 False)
       (codex:unified-exec-process-meta 1 10 True)
       (codex:unified-exec-process-meta 3 30 False))))
  (5 3 1))

!(assertEqual
  (codex:unified-exec-process-id-list-contains 3 (10 9 8 7 6 5 4 3))
  True)

!(assertEqual
  (codex:unified-exec-process-id-list-contains 2 (10 9 8 7 6 5 4 3))
  False)

!(assertEqual
  (codex:unified-exec-process-id-to-prune-from-meta
    (codex-pruning-meta-10 True False False))
  2)

!(assertEqual
  (codex:unified-exec-process-id-to-prune-from-meta
    (codex-pruning-meta-10 False False False))
  1)

!(assertEqual
  (codex:unified-exec-process-id-to-prune-from-meta
    (codex-pruning-meta-10 False True True))
  1)

!(assertEqual
  (codex:unified-exec-process-id-to-prune-from-meta
    ((codex:unified-exec-process-meta 1 1 False)
     (codex:unified-exec-process-meta 2 2 False)
     (codex:unified-exec-process-meta 3 3 False)
     (codex:unified-exec-process-meta 4 4 False)
     (codex:unified-exec-process-meta 5 5 False)
     (codex:unified-exec-process-meta 6 6 False)
     (codex:unified-exec-process-meta 7 7 False)
     (codex:unified-exec-process-meta 8 8 False)))
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-process-id-to-prune-from-meta
    ((codex:unified-exec-process-meta 1 1 True)
     (codex:unified-exec-process-meta 2 2 True)
     (codex:unified-exec-process-meta 3 3 True)
     (codex:unified-exec-process-meta 4 4 True)
     (codex:unified-exec-process-meta 5 5 True)
     (codex:unified-exec-process-meta 6 6 True)
     (codex:unified-exec-process-meta 7 7 True)
     (codex:unified-exec-process-meta 8 8 True)
     (codex:unified-exec-process-meta 9 9 True)))
  1)

!(assertEqual
  (codex:unified-exec-process-prune-if-needed-from-meta
    ((codex:unified-exec-process-meta 1 1 True)
     (codex:unified-exec-process-meta 2 2 False)
     (codex:unified-exec-process-meta 3 3 False)
     (codex:unified-exec-process-meta 4 4 False)
     (codex:unified-exec-process-meta 5 5 False)
     (codex:unified-exec-process-meta 6 6 False)
     (codex:unified-exec-process-meta 7 7 False)
     (codex:unified-exec-process-meta 8 8 False)
     (codex:unified-exec-process-meta 9 9 False)
     (codex:unified-exec-process-meta 10 10 False)
     (codex:unified-exec-process-meta 11 11 False)
     (codex:unified-exec-process-meta 12 12 False)
     (codex:unified-exec-process-meta 13 13 False)
     (codex:unified-exec-process-meta 14 14 False)
     (codex:unified-exec-process-meta 15 15 False)
     (codex:unified-exec-process-meta 16 16 False)
     (codex:unified-exec-process-meta 17 17 False)
     (codex:unified-exec-process-meta 18 18 False)
     (codex:unified-exec-process-meta 19 19 False)
     (codex:unified-exec-process-meta 20 20 False)
     (codex:unified-exec-process-meta 21 21 False)
     (codex:unified-exec-process-meta 22 22 False)
     (codex:unified-exec-process-meta 23 23 False)
     (codex:unified-exec-process-meta 24 24 False)
     (codex:unified-exec-process-meta 25 25 False)
     (codex:unified-exec-process-meta 26 26 False)
     (codex:unified-exec-process-meta 27 27 False)
     (codex:unified-exec-process-meta 28 28 False)
     (codex:unified-exec-process-meta 29 29 False)
     (codex:unified-exec-process-meta 30 30 False)
     (codex:unified-exec-process-meta 31 31 False)
     (codex:unified-exec-process-meta 32 32 False)
     (codex:unified-exec-process-meta 33 33 False)
     (codex:unified-exec-process-meta 34 34 False)
     (codex:unified-exec-process-meta 35 35 False)
     (codex:unified-exec-process-meta 36 36 False)
     (codex:unified-exec-process-meta 37 37 False)
     (codex:unified-exec-process-meta 38 38 False)
     (codex:unified-exec-process-meta 39 39 False)
     (codex:unified-exec-process-meta 40 40 False)
     (codex:unified-exec-process-meta 41 41 False)
     (codex:unified-exec-process-meta 42 42 False)
     (codex:unified-exec-process-meta 43 43 False)
     (codex:unified-exec-process-meta 44 44 False)
     (codex:unified-exec-process-meta 45 45 False)
     (codex:unified-exec-process-meta 46 46 False)
     (codex:unified-exec-process-meta 47 47 False)
     (codex:unified-exec-process-meta 48 48 False)
     (codex:unified-exec-process-meta 49 49 False)
     (codex:unified-exec-process-meta 50 50 False)
     (codex:unified-exec-process-meta 51 51 False)
     (codex:unified-exec-process-meta 52 52 False)
     (codex:unified-exec-process-meta 53 53 False)
     (codex:unified-exec-process-meta 54 54 False)
     (codex:unified-exec-process-meta 55 55 False)
     (codex:unified-exec-process-meta 56 56 False)
     (codex:unified-exec-process-meta 57 57 False)
     (codex:unified-exec-process-meta 58 58 False)
     (codex:unified-exec-process-meta 59 59 False)
     (codex:unified-exec-process-meta 60 60 False)
     (codex:unified-exec-process-meta 61 61 False)
     (codex:unified-exec-process-meta 62 62 False)
     (codex:unified-exec-process-meta 63 63 False)
     (codex:unified-exec-process-meta 64 64 False)))
  1)
