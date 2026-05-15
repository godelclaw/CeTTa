; Narrow Rust-faithful AgentPath slice.
;
; This ports:
; - openai-codex/codex-rs/protocol/src/agent_path.rs
;
; Covered in this increment:
; - root / morpheus constructors
; - from_string validation
; - as_str / is_root / name
; - join
; - resolve
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `Result<AgentPath, String>`. The current CeTTa port preserves the
;   same visible success/error behavior through explicit `CodexAgentPathOk` and
;   `CodexAgentPathErr` result constructors.
; - Rust validates characters via ASCII predicates. The current CeTTa port uses
;   `str-find` against the exact allowed-character set while preserving the same
;   acceptance surface.
; - The public constructor/join/resolve helpers force the validation step
;   through `once` because the current CeTTa reducer can otherwise emit
;   duplicate equivalent results across recursive validation paths.

!(import! &self list)
!(import! &self str)

(= (codex:agent-path $path)
   (CodexAgentPath $path))

(= (codex:agent-path-ok $path)
   (CodexAgentPathOk $path))

(= (codex:agent-path-err $message)
   (CodexAgentPathErr $message))

(= (codex:agent-path-root)
   (codex:agent-path "/root"))

(= (codex:agent-path-morpheus)
   (codex:agent-path "/morpheus"))

(= (codex:agent-path-as-str (CodexAgentPath $path))
   $path)

(= (codex:is-agent-path-root (CodexAgentPath $path))
   (== $path "/root"))

(= (codex:last-non-empty-agent-path-segment () $fallback)
   $fallback)

(= (codex:last-non-empty-agent-path-segment $segments $fallback)
   (let $head (list:first $segments)
     (let $tail (list:rest $segments)
       (let $next-fallback
         (if (== $head "") $fallback $head)
         (codex:last-non-empty-agent-path-segment $tail $next-fallback)))))

(= (codex:agent-path-name $path)
   (if (codex:is-agent-path-root $path)
       "root"
       (codex:last-non-empty-agent-path-segment
         (str-split "/" (codex:agent-path-as-str $path))
         "root")))

(= (codex:is-valid-agent-name-char $char)
   (let $found (str-find "abcdefghijklmnopqrstuvwxyz0123456789_" $char)
     (if (== $found Empty)
         False
         True)))

(= (codex:is-valid-agent-name-text "")
   True)

(= (codex:is-valid-agent-name-text $text)
   (if (== (str-length $text) 0)
       True
       (if (codex:is-valid-agent-name-char (str-slice $text 0 1))
           (codex:is-valid-agent-name-text
             (str-slice $text 1 (str-length $text)))
           False)))

(= (codex:validate-agent-name $agent-name)
   (if (== $agent-name "")
       "agent_name must not be empty"
       (if (== $agent-name "root")
           "agent_name `root` is reserved"
           (if (== $agent-name ".")
               "agent_name `.` is reserved"
               (if (== $agent-name "..")
                   "agent_name `..` is reserved"
                   (let $slash-index (str-find $agent-name "/")
                     (if (not (== $slash-index Empty))
                         "agent_name must not contain `/`"
                         (let $is-valid
                           (codex:is-valid-agent-name-text $agent-name)
                           (if $is-valid
                               Empty
                               "agent_name must use only lowercase letters, digits, and underscores")))))))))

(= (codex:validate-agent-name-segments ())
   Empty)

(= (codex:validate-agent-name-segments $segments)
   (let $head (list:first $segments)
     (let $tail (list:rest $segments)
       (let $head-validation (codex:validate-agent-name $head)
         (if (== $head-validation Empty)
             (codex:validate-agent-name-segments $tail)
             $head-validation)))))

(= (codex:validate-absolute-agent-path $path)
   (if (== $path "/morpheus")
       Empty
       (if (not (str-starts-with? $path "/"))
           "absolute agent paths must start with `/root` or be `/morpheus`"
           (let $stripped (str-slice $path 1 (str-length $path))
             (let $segments (str-split "/" $stripped)
               (let $root (list:first $segments)
                 (if (not (== $root "root"))
                     "absolute agent paths must start with `/root` or be `/morpheus`"
                     (if (str-ends-with? $stripped "/")
                         "absolute agent path must not end with `/`"
                         (codex:validate-agent-name-segments
                           (list:rest $segments))))))))))

(= (codex:validate-relative-agent-reference $reference)
   (if (str-ends-with? $reference "/")
       "relative agent path must not end with `/`"
       (codex:validate-agent-name-segments (str-split "/" $reference))))

(= (codex:agent-path-from-string $path)
   (let $validation (once (codex:validate-absolute-agent-path $path))
     (if (== $validation Empty)
         (codex:agent-path-ok (codex:agent-path $path))
         (codex:agent-path-err $validation))))

(= (codex:agent-path-join $path $agent-name)
   (let $validation (once (codex:validate-agent-name $agent-name))
     (if (== $validation Empty)
         (codex:agent-path-from-string
           (str-concat
             (str-concat (codex:agent-path-as-str $path) "/")
             $agent-name))
         (codex:agent-path-err $validation))))

(= (codex:agent-path-resolve $path $reference)
   (if (== $reference "")
       (codex:agent-path-err "agent path must not be empty")
       (if (== $reference "/root")
           (codex:agent-path-ok (codex:agent-path-root))
           (if (str-starts-with? $reference "/")
               (codex:agent-path-from-string $reference)
               (let $validation
                 (once (codex:validate-relative-agent-reference $reference))
                 (if (== $validation Empty)
                     (codex:agent-path-from-string
                       (str-concat
                         (str-concat (codex:agent-path-as-str $path) "/")
                         $reference))
                     (codex:agent-path-err $validation)))))))
