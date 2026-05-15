; Narrow Rust-faithful image-detail helper slice.
;
; This ports:
; - openai-codex/codex-rs/tools/src/image_detail.rs
;
; Covered in this increment:
; - can_request_original_image_detail
; - normalize_output_image_detail
; - sanitize_original_image_detail
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust takes `ModelInfo` and `Option<ImageDetail>`. The current restarted
;   CeTTa slice matches the already-ported narrow `CodexToolConfigModelInfo`
;   constructor shape and uses `CodexAbsent` for omitted optional detail values.
; - Rust mutates `&mut [FunctionCallOutputContentItem]` in place. CeTTa terms
;   are immutable, so this port rebuilds and returns the sanitized item list
;   while preserving the same visible content-item payload.
; - Rust imports `DEFAULT_IMAGE_DETAIL` from the shared protocol crate. The
;   current CeTTa evaluator can duplicate downstream reductions if this helper
;   re-imports `protocol` into modules that already import it, so this slice
;   keeps the same `"high"` constant locally.

(= (codex:image-detail-default-detail)
   "high")

(= (codex:can-request-original-image-detail
      (CodexToolConfigModelInfo
        $shell-type
        $apply-patch-tool-type
        $experimental-supported-tools
        $can-request-original-image-detail))
   $can-request-original-image-detail)

(= (codex:normalize-output-image-detail $model-info "original")
   (if (codex:can-request-original-image-detail $model-info)
       "original"
       CodexAbsent))

(= (codex:normalize-output-image-detail $model-info CodexAbsent)
   CodexAbsent)

(= (codex:normalize-output-image-detail $model-info "auto")
   "auto")

(= (codex:normalize-output-image-detail $model-info "low")
   "low")

(= (codex:normalize-output-image-detail $model-info "high")
   "high")

(= (codex:sanitize-original-image-detail-item True $item)
   $item)

(= (codex:sanitize-original-image-detail-item False $item)
   (case $item
     (((CodexInputImage $image-url "original")
       (CodexInputImage $image-url (codex:image-detail-default-detail)))
      ($other $other))))

(= (codex:sanitize-original-image-detail-items $supported ())
   ())

(= (codex:sanitize-original-image-detail-items $supported $items)
   (let ($head $tail) (decons-atom $items)
     (let $sanitized-head
       (codex:sanitize-original-image-detail-item $supported $head)
       (case (codex:sanitize-original-image-detail-items $supported $tail)
         (($sanitized-tail
           (cons-atom $sanitized-head $sanitized-tail)))))))
