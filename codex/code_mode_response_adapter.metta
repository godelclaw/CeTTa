; Rust-faithful code-mode response adapter slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/tools/code_mode/response_adapter.rs
; - openai-codex/codex-rs/code-mode/src/response.rs
;
; Covered in this increment:
; - IntoProtocol<ImageDetail> for codex_code_mode::ImageDetail
; - IntoProtocol<FunctionCallOutputContentItem>
; - into_function_call_output_content_items
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses private trait dispatch over enum variants. This CeTTa port uses
;   explicit constructors and reducer functions for the same variants.
; - Rust represents `Option<ImageDetail>` as `None`; this codebase represents
;   omitted optional fields as `CodexAbsent` until JSON projection.

; Rust imports `codex_protocol::models::DEFAULT_IMAGE_DETAIL`; the existing
; restarted image-detail slice exposes the same visible `"high"` protocol
; default without pulling in the large protocol module here.
!(import! &self image_detail)

(= (codex:code-mode-input-text $text)
   (CodexCodeModeInputText $text))

(= (codex:code-mode-input-image $image-url)
   (CodexCodeModeInputImage $image-url CodexAbsent))

(= (codex:code-mode-input-image $image-url $detail)
   (CodexCodeModeInputImage $image-url $detail))

(= (codex:code-mode-response-adapter-image-detail-into-protocol "auto")
   "auto")

(= (codex:code-mode-response-adapter-image-detail-into-protocol "low")
   "low")

(= (codex:code-mode-response-adapter-image-detail-into-protocol "high")
   "high")

(= (codex:code-mode-response-adapter-image-detail-into-protocol "original")
   "original")

(= (codex:code-mode-response-adapter-image-detail-or-default CodexAbsent)
   (codex:image-detail-default-detail))

(= (codex:code-mode-response-adapter-image-detail-or-default "auto")
   (codex:code-mode-response-adapter-image-detail-into-protocol "auto"))

(= (codex:code-mode-response-adapter-image-detail-or-default "low")
   (codex:code-mode-response-adapter-image-detail-into-protocol "low"))

(= (codex:code-mode-response-adapter-image-detail-or-default "high")
   (codex:code-mode-response-adapter-image-detail-into-protocol "high"))

(= (codex:code-mode-response-adapter-image-detail-or-default "original")
   (codex:code-mode-response-adapter-image-detail-into-protocol "original"))

(= (codex:code-mode-response-adapter-content-item-into-protocol
      (CodexCodeModeInputText $text))
   (CodexInputText $text))

(= (codex:code-mode-response-adapter-content-item-into-protocol
      (CodexCodeModeInputImage $image-url $detail))
   (CodexInputImage
     $image-url
     (codex:code-mode-response-adapter-image-detail-or-default $detail)))

(= (codex:code-mode-response-adapter-content-items-into-protocol ())
   ())

(= (codex:code-mode-response-adapter-content-items-into-protocol $items)
   (let ($head $tail) (decons-atom $items)
     (let $mapped-head
       (codex:code-mode-response-adapter-content-item-into-protocol $head)
       (case (codex:code-mode-response-adapter-content-items-into-protocol $tail)
         (($mapped-tail
           (cons-atom $mapped-head $mapped-tail)))))))

(= (codex:into-function-call-output-content-items $items)
   (codex:code-mode-response-adapter-content-items-into-protocol $items))
