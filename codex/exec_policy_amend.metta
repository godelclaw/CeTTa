; Rust-faithful exec-policy amendment slice.
;
; This ports the visible amendment behavior from:
; - openai-codex/codex-rs/execpolicy/src/amend.rs
;
; Covered in this increment:
; - allow-prefix rule line formatting
; - network-rule line formatting with host normalization and decision spelling
; - duplicate-line suppression and newline insertion when appending
; - file-backed append helpers for prefix and network rules
;
; Required CeTTa deviation for audit:
; - Rust uses advisory file locking while reading and appending. The current
;   CeTTa runtime exposes ordinary fs read/write primitives but no advisory
;   lock primitive, so the file-backed helpers preserve the same sequential
;   visible behavior and error surface where available, but are not yet
;   concurrency-equivalent under simultaneous writers.

!(import! &self exec_policy)
!(import! &self fs)
!(import! &self json)
!(import! &self path)
!(import! &self process)
!(import! &self str)

(= (codex:exec-policy-amend-ok $value)
   (CodexExecPolicyAmendOk $value))

(= (codex:exec-policy-amend-error $error)
   (CodexExecPolicyAmendError $error))

(= (codex:exec-policy-amend-value
      (CodexExecPolicyAmendOk $value))
   $value)

(= (codex:exec-policy-amend-error-value
      (CodexExecPolicyAmendError $error))
   $error)

(= (codex:exec-policy-amend-error-message
      (CodexExecPolicyAmendErrorEmptyPrefix))
   "prefix rule requires at least one token")

(= (codex:exec-policy-amend-error-message
      (CodexExecPolicyAmendErrorInvalidNetworkRule $message))
   (str-concat "invalid network rule: " $message))

(= (codex:exec-policy-amend-error-message
      (CodexExecPolicyAmendErrorMissingParent $path))
   (str-concat "policy path has no parent: " $path))

(= (codex:exec-policy-amend-error-message
      (CodexExecPolicyAmendErrorCreatePolicyDir $dir $source))
   (str-concat
     "failed to create policy directory "
     (str-concat $dir (str-concat ": " $source))))

(= (codex:exec-policy-amend-error-message
      (CodexExecPolicyAmendErrorReadPolicyFile $path $source))
   (str-concat
     "failed to read policy file "
     (str-concat $path (str-concat ": " $source))))

(= (codex:exec-policy-amend-error-message
      (CodexExecPolicyAmendErrorWritePolicyFile $path $source))
   (str-concat
     "failed to write to policy file "
     (str-concat $path (str-concat ": " $source))))

(= (codex:exec-policy-amend-json-string $text)
   (json-stringify (JsonString $text)))

(= (codex:exec-policy-amend-json-string-list $values)
   (str-concat
     "["
     (str-concat
       (codex:exec-policy-amend-json-string-list-inner $values)
       "]")))

(= (codex:exec-policy-amend-json-string-list-inner $values)
   (if (== $values ())
       ""
       (let $head (list:first $values)
         (let $tail (list:rest $values)
           (if (== $tail ())
               (codex:exec-policy-amend-json-string $head)
               (str-concat
                 (codex:exec-policy-amend-json-string $head)
                 (str-concat
                   ", "
                   (codex:exec-policy-amend-json-string-list-inner
                     $tail))))))))

(= (codex:exec-policy-amend-format-allow-prefix-rule $prefix)
   (if (== $prefix ())
       (codex:exec-policy-amend-error
         (CodexExecPolicyAmendErrorEmptyPrefix))
       (codex:exec-policy-amend-ok
         (str-concat
           "prefix_rule(pattern="
           (str-concat
             (codex:exec-policy-amend-json-string-list $prefix)
             ", decision=\"allow\")")))))

(= (codex:exec-policy-amend-decision-policy-string $decision)
   (if (== $decision (codex:decision-forbidden))
       "deny"
       $decision))

(= (codex:exec-policy-amend-format-network-rule
      $host
      $protocol
      $decision)
   (codex:exec-policy-amend-format-network-rule
     $host
     $protocol
     $decision
     CodexAbsent))

(= (codex:exec-policy-amend-format-network-rule
      $host
      $protocol
      $decision
      $justification)
   (case (codex:normalize-network-rule-host $host)
     (((CodexExecPolicyNetworkRuleHostError $message)
       (codex:exec-policy-amend-error
         (CodexExecPolicyAmendErrorInvalidNetworkRule
           (str-concat "invalid rule: " $message))))
      ((CodexExecPolicyNetworkRuleHostOk $normalized-host)
       (if (and
             (not (== $justification CodexAbsent))
             (== (str-trim $justification) ""))
           (codex:exec-policy-amend-error
             (CodexExecPolicyAmendErrorInvalidNetworkRule
               "justification cannot be empty"))
           (codex:exec-policy-amend-ok
             (codex:exec-policy-amend-network-rule-line
               $normalized-host
               $protocol
               $decision
               $justification)))))))

(= (codex:exec-policy-amend-network-rule-line
      $host
      $protocol
      $decision
      $justification)
   (str-concat
     "network_rule(host="
     (str-concat
       (codex:exec-policy-amend-json-string $host)
       (str-concat
         ", protocol="
         (str-concat
           (codex:exec-policy-amend-json-string
             (codex:network-rule-protocol-policy-string $protocol))
           (str-concat
             ", decision="
             (str-concat
               (codex:exec-policy-amend-json-string
                 (codex:exec-policy-amend-decision-policy-string
                   $decision))
               (if (== $justification CodexAbsent)
                   ")"
                   (str-concat
                     ", justification="
                     (str-concat
                       (codex:exec-policy-amend-json-string $justification)
                       ")"))))))))))

(= (codex:exec-policy-amend-lines-contain? () $line)
   False)

(= (codex:exec-policy-amend-lines-contain? $lines $line)
   (let $head (list:first $lines)
     (let $tail (list:rest $lines)
       (if (== $head $line)
           True
           (codex:exec-policy-amend-lines-contain? $tail $line)))))

(= (codex:exec-policy-amend-contents-has-line? $contents $line)
   (codex:exec-policy-amend-lines-contain?
     (str-split "\n" $contents)
     $line))

(= (codex:exec-policy-amend-append-line-to-contents
      $contents
      $line)
   (if (codex:exec-policy-amend-contents-has-line? $contents $line)
       $contents
       (if (== $contents "")
           (str-concat $line "\n")
           (if (str-ends-with? $contents "\n")
               (str-concat $contents (str-concat $line "\n"))
               (str-concat
                 $contents
                 (str-concat "\n" (str-concat $line "\n")))))))

(= (codex:exec-policy-amend-parent-dir $policy-path)
   (path-dirname $policy-path))

(= (codex:exec-policy-amend-ensure-parent-dir $policy-path)
   (let $dir (codex:exec-policy-amend-parent-dir $policy-path)
     (if (and (== (path-normalize $policy-path) "/") (== $dir "/"))
         (codex:exec-policy-amend-error
           (CodexExecPolicyAmendErrorMissingParent $policy-path))
         (if (fs-exists? $dir)
             (codex:exec-policy-amend-ok ())
             (let $result
               (process-run-cmd-cwd-env-timeout-cap-bytes
                 ("mkdir" $dir)
                 "/"
                 ()
                 1000
                 8192)
               (if (== (process-result-exit-code $result) 0)
                   (codex:exec-policy-amend-ok ())
                   (codex:exec-policy-amend-error
                     (CodexExecPolicyAmendErrorCreatePolicyDir
                       $dir
                       (process-result-stderr $result)))))))))

(= (codex:exec-policy-amend-read-policy-file $policy-path)
   (if (fs-exists? $policy-path)
       (case (fs-read-text $policy-path)
         (($contents
           (codex:exec-policy-amend-ok $contents))))
       (codex:exec-policy-amend-ok "")))

(= (codex:exec-policy-amend-write-policy-file
      $policy-path
      $contents)
   (case (fs-write-text $policy-path $contents)
     (($unit (codex:exec-policy-amend-ok ())))))

(= (codex:exec-policy-amend-append-rule-line $policy-path $line)
   (case (codex:exec-policy-amend-ensure-parent-dir $policy-path)
     (((CodexExecPolicyAmendError $error)
       (codex:exec-policy-amend-error $error))
      ((CodexExecPolicyAmendOk $unit)
       (case (codex:exec-policy-amend-read-policy-file $policy-path)
         (((CodexExecPolicyAmendError $error)
           (codex:exec-policy-amend-error $error))
          ((CodexExecPolicyAmendOk $contents)
           (let $updated
             (codex:exec-policy-amend-append-line-to-contents
               $contents
               $line)
             (if (== $updated $contents)
                 (codex:exec-policy-amend-ok ())
                 (codex:exec-policy-amend-write-policy-file
                   $policy-path
                   $updated))))))))))

(= (codex:blocking-append-allow-prefix-rule $policy-path $prefix)
   (case (codex:exec-policy-amend-format-allow-prefix-rule $prefix)
     (((CodexExecPolicyAmendError $error)
       (codex:exec-policy-amend-error $error))
      ((CodexExecPolicyAmendOk $line)
       (codex:exec-policy-amend-append-rule-line $policy-path $line)))))

(= (codex:blocking-append-network-rule
      $policy-path
      $host
      $protocol
      $decision)
   (codex:blocking-append-network-rule
     $policy-path
     $host
     $protocol
     $decision
     CodexAbsent))

(= (codex:blocking-append-network-rule
      $policy-path
      $host
      $protocol
      $decision
      $justification)
   (case
     (codex:exec-policy-amend-format-network-rule
       $host
       $protocol
       $decision
       $justification)
     (((CodexExecPolicyAmendError $error)
       (codex:exec-policy-amend-error $error))
      ((CodexExecPolicyAmendOk $line)
       (codex:exec-policy-amend-append-rule-line $policy-path $line)))))
