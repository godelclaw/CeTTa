; Rust-faithful pure unified-exec head/tail buffer slice.
;
; This ports the deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/unified_exec/head_tail_buffer.rs
;
; Covered in this increment:
; - HeadTailBuffer::default
; - HeadTailBuffer::new
; - retained_bytes / omitted_bytes
; - push_chunk / push_to_tail / trim_tail_to_budget
; - snapshot_chunks / to_bytes
; - drain_chunks
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores arbitrary `Vec<u8>` chunks and measures byte length. The current
;   CeTTa process/text surface represents chunks as strings, so this slice uses
;   `str-length` and `str-slice`. The algorithm and accounting match Rust for
;   ASCII/text output chunks, which is the currently exposed CeTTa unified-exec
;   output boundary; arbitrary binary-byte preservation belongs with a later
;   byte-vector library slice.
; - Rust mutates `self`. CeTTa returns a new buffer value for update operations,
;   and `drain_chunks` returns both drained chunks and the reset buffer.
; - CeTTa's `floor-math` yields integer-valued floats, which cannot be consumed
;   by `str-slice`. The head/tail budget split uses a small integer recursive
;   helper so slice boundaries preserve the same integral `usize` shape Rust
;   uses.
; - Rust default delegates to `new(UNIFIED_EXEC_OUTPUT_MAX_BYTES)`. The CeTTa
;   default expands the known 1 MiB constant directly because the current
;   integer-half helper is recursive until CeTTa has a native integer division
;   or integer cast operation suitable for string slice boundaries.

!(import! &self list)
!(import! &self str)

(= (codex:unified-exec-output-max-bytes)
   1048576)

(= (codex:head-tail-buffer
      $max-bytes
      $head-budget
      $tail-budget
      $head
      $tail
      $head-bytes
      $tail-bytes
      $omitted-bytes)
   (CodexHeadTailBuffer
     $max-bytes
     $head-budget
     $tail-budget
     $head
     $tail
     $head-bytes
     $tail-bytes
     $omitted-bytes))

(= (codex:head-tail-buffer-new $max-bytes)
   (let $head-budget (codex:head-tail-buffer-half-floor $max-bytes)
     (let $tail-budget (- $max-bytes $head-budget)
       (codex:head-tail-buffer
         $max-bytes
         $head-budget
         $tail-budget
         ()
         ()
         0
         0
         0))))

(= (codex:head-tail-buffer-default)
   (codex:head-tail-buffer
     (codex:unified-exec-output-max-bytes)
     524288
     524288
     ()
     ()
     0
     0
     0))

(= (codex:head-tail-buffer-half-floor $value)
   (codex:head-tail-buffer-half-floor-from $value 0))

(= (codex:head-tail-buffer-half-floor-from $remaining $acc)
   (if (< $remaining 2)
       $acc
       (codex:head-tail-buffer-half-floor-from
         (- $remaining 2)
         (+ $acc 1))))

(= (codex:head-tail-buffer-max-bytes
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   $max-bytes)

(= (codex:head-tail-buffer-head-budget
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   $head-budget)

(= (codex:head-tail-buffer-tail-budget
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   $tail-budget)

(= (codex:head-tail-buffer-head
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   $head)

(= (codex:head-tail-buffer-tail
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   $tail)

(= (codex:head-tail-buffer-head-bytes
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   $head-bytes)

(= (codex:head-tail-buffer-tail-bytes
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   $tail-bytes)

(= (codex:head-tail-buffer-retained-bytes
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   (+ $head-bytes $tail-bytes))

(= (codex:head-tail-buffer-omitted-bytes
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   $omitted-bytes)

(= (codex:head-tail-buffer-push-chunk $buffer $chunk)
   (case (once (eval $buffer))
     (((CodexHeadTailBuffer
         $max-bytes
         $head-budget
         $tail-budget
         $head
         $tail
         $head-bytes
         $tail-bytes
         $omitted-bytes)
       (let $chunk-len (eval (str-length $chunk))
         (if (== $max-bytes 0)
             (CodexHeadTailBuffer
               $max-bytes
               $head-budget
               $tail-budget
               $head
               $tail
               $head-bytes
               $tail-bytes
               (+ $omitted-bytes $chunk-len))
             (if (< $head-bytes $head-budget)
                 (let $remaining-head (- $head-budget $head-bytes)
                   (if (<= $chunk-len $remaining-head)
                       (CodexHeadTailBuffer
                         $max-bytes
                         $head-budget
                         $tail-budget
                         (eval (list:append $head ($chunk)))
                         $tail
                         (+ $head-bytes $chunk-len)
                         $tail-bytes
                         $omitted-bytes)
                       (let $head-part
                         (eval (str-slice $chunk 0 $remaining-head))
                         (let $tail-part
                           (eval (str-slice $chunk $remaining-head $chunk-len))
                           (let $head-next
                             (if (== $head-part "")
                                 $head
                                 (eval (list:append $head ($head-part))))
                             (let $head-bytes-next
                               (+ $head-bytes (eval (str-length $head-part)))
                               (codex:head-tail-buffer-push-to-tail
                                 (CodexHeadTailBuffer
                                   $max-bytes
                                   $head-budget
                                   $tail-budget
                                   $head-next
                                   $tail
                                   $head-bytes-next
                                   $tail-bytes
                                   $omitted-bytes)
                                 $tail-part)))))))
                 (codex:head-tail-buffer-push-to-tail
                   (CodexHeadTailBuffer
                     $max-bytes
                     $head-budget
                     $tail-budget
                     $head
                     $tail
                     $head-bytes
                     $tail-bytes
                     $omitted-bytes)
                   $chunk))))))))

(= (codex:head-tail-buffer-push-to-tail
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes)
      $chunk)
   (let $chunk-len (eval (str-length $chunk))
     (if (== $tail-budget 0)
         (CodexHeadTailBuffer
           $max-bytes
           $head-budget
           $tail-budget
           $head
           $tail
           $head-bytes
           $tail-bytes
           (+ $omitted-bytes $chunk-len))
         (if (>= $chunk-len $tail-budget)
             (let $start (- $chunk-len $tail-budget)
               (let $kept (eval (str-slice $chunk $start $chunk-len))
                 (let $kept-len (eval (str-length $kept))
                   (CodexHeadTailBuffer
                     $max-bytes
                     $head-budget
                     $tail-budget
                     $head
                     ($kept)
                     $head-bytes
                     $kept-len
                     (+ $omitted-bytes (+ $tail-bytes (- $chunk-len $kept-len)))))))
             (codex:head-tail-buffer-trim-tail-to-budget
               (CodexHeadTailBuffer
                 $max-bytes
                 $head-budget
                 $tail-budget
                 $head
                 (eval (list:append $tail ($chunk)))
                 $head-bytes
                 (+ $tail-bytes $chunk-len)
                 $omitted-bytes))))))

(= (codex:head-tail-buffer-trim-tail-to-budget
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   (let $excess (- $tail-bytes $tail-budget)
     (if (<= $excess 0)
         (CodexHeadTailBuffer
           $max-bytes
           $head-budget
           $tail-budget
           $head
           $tail
           $head-bytes
           $tail-bytes
           $omitted-bytes)
         (codex:head-tail-buffer-trim-tail-loop
           $max-bytes
           $head-budget
           $tail-budget
           $head
           $tail
           $head-bytes
           $tail-bytes
           $omitted-bytes
           $excess))))

(= (codex:head-tail-buffer-trim-tail-loop
      $max-bytes
      $head-budget
      $tail-budget
      $head
      ()
      $head-bytes
      $tail-bytes
      $omitted-bytes
      $excess)
   (CodexHeadTailBuffer
     $max-bytes
     $head-budget
     $tail-budget
     $head
     ()
     $head-bytes
     $tail-bytes
     $omitted-bytes))

(= (codex:head-tail-buffer-trim-tail-loop
      $max-bytes
      $head-budget
      $tail-budget
      $head
      $tail
      $head-bytes
      $tail-bytes
      $omitted-bytes
      $excess)
   (let $front (list:first $tail)
     (let $rest (list:rest $tail)
     (let $front-len (eval (str-length $front))
         (if (>= $excess $front-len)
             (codex:head-tail-buffer-trim-tail-loop
               $max-bytes
               $head-budget
               $tail-budget
               $head
               $rest
               $head-bytes
               (- $tail-bytes $front-len)
               (+ $omitted-bytes $front-len)
               (- $excess $front-len))
             (let $trimmed-front (eval (str-slice $front $excess $front-len))
               (CodexHeadTailBuffer
                 $max-bytes
                 $head-budget
                 $tail-budget
                 $head
                 (cons-atom $trimmed-front $rest)
                 $head-bytes
                 (- $tail-bytes $excess)
                 (+ $omitted-bytes $excess))))))))

(= (codex:head-tail-buffer-snapshot-chunks
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   (list:append $head $tail))

(= (codex:head-tail-buffer-to-bytes $buffer)
   (str-join "" (codex:head-tail-buffer-snapshot-chunks $buffer)))

(= (codex:head-tail-buffer-drain-result $chunks $buffer)
   (CodexHeadTailBufferDrainResult $chunks $buffer))

(= (codex:head-tail-buffer-drain-result-chunks
      (CodexHeadTailBufferDrainResult $chunks $buffer))
   $chunks)

(= (codex:head-tail-buffer-drain-result-buffer
      (CodexHeadTailBufferDrainResult $chunks $buffer))
   $buffer)

(= (codex:head-tail-buffer-drain-chunks
      (CodexHeadTailBuffer
        $max-bytes
        $head-budget
        $tail-budget
        $head
        $tail
        $head-bytes
        $tail-bytes
        $omitted-bytes))
   (codex:head-tail-buffer-drain-result
     (list:append $head $tail)
     (CodexHeadTailBuffer
       $max-bytes
       $head-budget
       $tail-budget
       ()
       ()
       0
       0
       0)))
