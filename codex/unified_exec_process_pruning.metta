; Rust-faithful pure unified-exec process pruning slice.
;
; This ports the deterministic pruning policy from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - prune_processes_if_needed
;   - process_id_to_prune_from_meta
;
; Covered in this increment:
; - MAX_UNIFIED_EXEC_PROCESSES / WARNING_UNIFIED_EXEC_PROCESSES constants
; - process metadata projection used by pruning
; - 8 most-recently-used process protection
; - exited-process preference outside that protected set
; - LRU fallback outside the protected set
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust metadata carries `tokio::time::Instant`; this pure CeTTa helper accepts
;   a comparable scalar timestamp where larger means more recently used. The
;   ordering contract is the same as Rust's `sort_by_key(Reverse(last_used))`
;   and `sort_by_key(last_used)`.
; - Rust builds a `HashSet<i32>` for protected process IDs. This slice uses a
;   list-backed membership helper because the protected set is fixed at eight
;   IDs, preserving the same observable pruning policy.
; - Rust returns `Option<i32>` and removes the process entry from the store in
;   the caller. This pure helper returns `CodexAbsent` for `None`; the eventual
;   mutable process store port will perform the actual removal.

!(import! &self list)

(= (codex:max-unified-exec-processes)
   64)

(= (codex:warning-unified-exec-processes)
   60)

(= (codex:unified-exec-pruning-protected-recent-count)
   8)

(= (codex:unified-exec-process-meta $process-id $last-used $has-exited)
   (CodexUnifiedExecProcessMeta $process-id $last-used $has-exited))

(= (codex:unified-exec-process-meta-process-id
      (CodexUnifiedExecProcessMeta $process-id $last-used $has-exited))
   $process-id)

(= (codex:unified-exec-process-meta-last-used
      (CodexUnifiedExecProcessMeta $process-id $last-used $has-exited))
   $last-used)

(= (codex:unified-exec-process-meta-has-exited
      (CodexUnifiedExecProcessMeta $process-id $last-used $has-exited))
   $has-exited)

(= (codex:unified-exec-process-prune-if-needed-from-meta $meta)
   (let $count (eval (list:len $meta))
     (if (< $count (codex:max-unified-exec-processes))
         CodexAbsent
         (codex:unified-exec-process-id-to-prune-from-meta $meta))))

(= (codex:unified-exec-process-id-to-prune-from-meta $meta)
   (if (== $meta ())
       CodexAbsent
       (let $by-recency
         (eval (codex:unified-exec-process-meta-sort-by-last-used-desc $meta))
         (let $protected
           (eval
             (codex:unified-exec-process-meta-take-process-ids
               (codex:unified-exec-pruning-protected-recent-count)
               $by-recency))
           (let $lru
             (eval (codex:unified-exec-process-meta-sort-by-last-used-asc $meta))
             (case (once (eval
                     (codex:unified-exec-process-prune-first-exited
                       $lru
                       $protected)))
               ((CodexAbsent
                 (codex:unified-exec-process-prune-first-unprotected
                   $lru
                   $protected))
                ($process-id $process-id))))))))

(= (codex:unified-exec-process-meta-sort-by-last-used-asc $items)
   (if (== $items ())
       ()
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (let $sorted-tail
             (eval
               (codex:unified-exec-process-meta-sort-by-last-used-asc $tail))
             (codex:unified-exec-process-meta-insert-asc
               $head
               $sorted-tail))))))

(= (codex:unified-exec-process-meta-insert-asc $item $sorted)
   (if (== $sorted ())
       ($item)
       (let $head (list:first $sorted)
         (let $tail (list:rest $sorted)
           (let $item-last-used
             (eval (codex:unified-exec-process-meta-last-used $item))
             (let $head-last-used
               (eval (codex:unified-exec-process-meta-last-used $head))
               (if (<= $item-last-used $head-last-used)
                   (cons-atom $item $sorted)
                   (let $rest
                     (eval
                       (codex:unified-exec-process-meta-insert-asc
                         $item
                         $tail))
                     (cons-atom $head $rest)))))))))

(= (codex:unified-exec-process-meta-sort-by-last-used-desc $items)
   (if (== $items ())
       ()
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (let $sorted-tail
             (eval
               (codex:unified-exec-process-meta-sort-by-last-used-desc $tail))
             (codex:unified-exec-process-meta-insert-desc
               $head
               $sorted-tail))))))

(= (codex:unified-exec-process-meta-insert-desc $item $sorted)
   (if (== $sorted ())
       ($item)
       (let $head (list:first $sorted)
         (let $tail (list:rest $sorted)
           (let $item-last-used
             (eval (codex:unified-exec-process-meta-last-used $item))
             (let $head-last-used
               (eval (codex:unified-exec-process-meta-last-used $head))
               (if (>= $item-last-used $head-last-used)
                   (cons-atom $item $sorted)
                   (let $rest
                     (eval
                       (codex:unified-exec-process-meta-insert-desc
                         $item
                         $tail))
                     (cons-atom $head $rest)))))))))

(= (codex:unified-exec-process-meta-take-process-ids $count $items)
   (if (== $count 0)
       ()
       (if (== $items ())
           ()
           (let $head (list:first $items)
             (let $tail (list:rest $items)
               (let $process-id
                 (eval (codex:unified-exec-process-meta-process-id $head))
                 (let $rest
                   (eval
                     (codex:unified-exec-process-meta-take-process-ids
                       (- $count 1)
                       $tail))
                   (cons-atom $process-id $rest))))))))

(= (codex:unified-exec-process-id-list-contains $process-id $ids)
   (if (== $ids ())
       False
       (let $head (list:first $ids)
         (let $tail (list:rest $ids)
           (if (== $process-id $head)
               True
               (codex:unified-exec-process-id-list-contains
                 $process-id
                 $tail))))))

(= (codex:unified-exec-process-meta-is-protected $meta $protected)
   (let $process-id
     (eval (codex:unified-exec-process-meta-process-id $meta))
     (codex:unified-exec-process-id-list-contains
       $process-id
       $protected)))

(= (codex:unified-exec-process-prune-first-exited $lru $protected)
   (if (== $lru ())
       CodexAbsent
       (let $head (list:first $lru)
         (let $tail (list:rest $lru)
           (let $is-protected
             (eval
               (codex:unified-exec-process-meta-is-protected
                 $head
                 $protected))
             (let $has-exited
               (eval (codex:unified-exec-process-meta-has-exited $head))
               (if (and (not $is-protected) $has-exited)
                   (codex:unified-exec-process-meta-process-id $head)
                   (codex:unified-exec-process-prune-first-exited
                     $tail
                     $protected))))))))

(= (codex:unified-exec-process-prune-first-unprotected $lru $protected)
   (if (== $lru ())
       CodexAbsent
       (let $head (list:first $lru)
         (let $tail (list:rest $lru)
           (let $is-protected
             (eval
               (codex:unified-exec-process-meta-is-protected
                 $head
                 $protected))
             (if (not $is-protected)
                 (codex:unified-exec-process-meta-process-id $head)
                 (codex:unified-exec-process-prune-first-unprotected
                   $tail
                   $protected)))))))
