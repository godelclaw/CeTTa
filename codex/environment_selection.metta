; Rust-faithful pure turn environment selection slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/environment_selection.rs
; - openai-codex/codex-rs/exec-server/src/environment.rs, only the
;   EnvironmentManager default-id and lookup behavior needed by that core slice.
;
; Covered in this increment:
; - local/remote environment id constants
; - exec-server URL normalization for manager default selection
; - default_thread_environment_selections
; - validate_environment_selections
; - selected_primary_environment
;
; Required CeTTa representation notes for audit:
; - Rust stores `Arc<Environment>` instances in a `HashMap`. This pure CeTTa
;   boundary represents environments as ordered manager entries. Lookup result
;   semantics match `HashMap::get`; entry order is not Rust-visible.
; - Rust `Environment` bundles filesystem/process/http backends. This slice only
;   needs the selected environment identity and remote URL metadata; backend
;   behavior belongs to the exec runtime/filesystem slices.

!(import! &self error)
!(import! &self list)
!(import! &self protocol)
!(import! &self str)

(= (codex:local-environment-id)
   "local")

(= (codex:remote-environment-id)
   "remote")

(= (codex:environment-selection-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:environment-selection-ascii-lower-text $text)
   (if (== $text "")
       ""
       (let $head
         (codex:environment-selection-ascii-lower-char
           (str-slice $text 0 1))
         (let $tail
           (eval
             (codex:environment-selection-ascii-lower-text
               (str-slice $text 1 (str-length $text))))
           (str-concat $head $tail)))))

(= (codex:environment-selection-is-none-url $text)
   (let $len (str-length $text)
     (if (== $len 4)
         (let $c0
           (codex:environment-selection-ascii-lower-char
             (str-slice $text 0 1))
           (let $c1
             (codex:environment-selection-ascii-lower-char
               (str-slice $text 1 2))
             (let $c2
               (codex:environment-selection-ascii-lower-char
                 (str-slice $text 2 3))
               (let $c3
                 (codex:environment-selection-ascii-lower-char
                   (str-slice $text 3 4))
                 (and
                   (== $c0 "n")
                   (and
                     (== $c1 "o")
                     (and
                       (== $c2 "n")
                       (== $c3 "e"))))))))
         False)))

(= (codex:environment-normalized-exec-server-url $url $disabled)
   (CodexEnvironmentNormalizedExecServerUrl $url $disabled))

(= (codex:environment-normalized-exec-server-url-value
      (CodexEnvironmentNormalizedExecServerUrl $url $disabled))
   $url)

(= (codex:environment-normalized-exec-server-url-disabled
      (CodexEnvironmentNormalizedExecServerUrl $url $disabled))
   $disabled)

(= (codex:environment-normalize-exec-server-url $exec-server-url)
   (if (== $exec-server-url CodexAbsent)
       (codex:environment-normalized-exec-server-url CodexAbsent False)
       (let $trimmed (str-trim $exec-server-url)
         (if (== $trimmed "")
             (codex:environment-normalized-exec-server-url CodexAbsent False)
             (let $is-none
               (codex:environment-selection-is-none-url $trimmed)
               (if $is-none
                   (codex:environment-normalized-exec-server-url CodexAbsent True)
                   (codex:environment-normalized-exec-server-url $trimmed False)))))))

(= (codex:environment $environment-id $is-remote $exec-server-url)
   (CodexEnvironment $environment-id $is-remote $exec-server-url))

(= (codex:environment-id (CodexEnvironment $environment-id $is-remote $exec-server-url))
   $environment-id)

(= (codex:environment-is-remote
      (CodexEnvironment $environment-id $is-remote $exec-server-url))
   $is-remote)

(= (codex:environment-exec-server-url
      (CodexEnvironment $environment-id $is-remote $exec-server-url))
   $exec-server-url)

(= (codex:environment-local)
   (codex:environment
     (codex:local-environment-id)
     False
     CodexAbsent))

(= (codex:environment-remote $exec-server-url)
   (codex:environment
     (codex:remote-environment-id)
     True
     $exec-server-url))

(= (codex:environment-manager-entry $environment-id $environment)
   (CodexEnvironmentManagerEntry $environment-id $environment))

(= (codex:environment-manager-entry-id
      (CodexEnvironmentManagerEntry $environment-id $environment))
   $environment-id)

(= (codex:environment-manager-entry-environment
      (CodexEnvironmentManagerEntry $environment-id $environment))
   $environment)

(= (codex:environment-manager $default-environment-id $environments)
   (CodexEnvironmentManager $default-environment-id $environments))

(= (codex:environment-manager-default-environment-id
      (CodexEnvironmentManager $default-environment-id $environments))
   $default-environment-id)

(= (codex:environment-manager-environments
      (CodexEnvironmentManager $default-environment-id $environments))
   $environments)

(= (codex:environment-manager-default-for-tests)
   (codex:environment-manager
     (codex:local-environment-id)
     ((codex:environment-manager-entry
        (codex:local-environment-id)
        (codex:environment-local)))))

(= (codex:environment-manager-from-exec-server-url $exec-server-url)
   (let $normalized
     (codex:environment-normalize-exec-server-url $exec-server-url)
     (if (codex:environment-normalized-exec-server-url-disabled $normalized)
         (codex:environment-manager
           CodexAbsent
           ((codex:environment-manager-entry
              (codex:local-environment-id)
              (codex:environment-local))))
         (if (== (codex:environment-normalized-exec-server-url-value $normalized)
                 CodexAbsent)
             (codex:environment-manager
               (codex:local-environment-id)
               ((codex:environment-manager-entry
                  (codex:local-environment-id)
                  (codex:environment-local))))
             (codex:environment-manager
               (codex:remote-environment-id)
               ((codex:environment-manager-entry
                  (codex:local-environment-id)
                  (codex:environment-local))
                (codex:environment-manager-entry
                  (codex:remote-environment-id)
                  (codex:environment-remote
                    (codex:environment-normalized-exec-server-url-value
                      $normalized)))))))))

(= (codex:environment-manager-get-from-entries () $environment-id)
   CodexAbsent)

(= (codex:environment-manager-get-from-entries $environments $environment-id)
   (let $head (list:first $environments)
     (let $tail (list:rest $environments)
       (if (== (codex:environment-manager-entry-id $head) $environment-id)
           (codex:environment-manager-entry-environment $head)
           (codex:environment-manager-get-from-entries
             $tail
             $environment-id)))))

(= (codex:environment-manager-get-environment
      (CodexEnvironmentManager $default-environment-id $environments)
      $environment-id)
   (codex:environment-manager-get-from-entries $environments $environment-id))

(= (codex:environment-manager-default-environment $manager)
   (let $environment-id (codex:environment-manager-default-environment-id $manager)
     (if (== $environment-id CodexAbsent)
         CodexAbsent
         (codex:environment-manager-get-environment $manager $environment-id))))

(= (codex:turn-environment-selection-environment-id
      (CodexTurnEnvironmentSelection $environment-id $cwd))
   $environment-id)

(= (codex:turn-environment-selection-cwd
      (CodexTurnEnvironmentSelection $environment-id $cwd))
   $cwd)

(= (codex:default-thread-environment-selections $environment-manager $cwd)
   (let $default-environment-id
     (codex:environment-manager-default-environment-id $environment-manager)
     (if (== $default-environment-id CodexAbsent)
         ()
         ((codex:turn-environment-selection $default-environment-id $cwd)))))

(= (codex:environment-selection-result-ok $value)
   (CodexEnvironmentSelectionOk $value))

(= (codex:environment-selection-result-err $error)
   (CodexEnvironmentSelectionErr $error))

(= (codex:environment-selection-result-value
      (CodexEnvironmentSelectionOk $value))
   $value)

(= (codex:environment-selection-result-error
      (CodexEnvironmentSelectionErr $error))
   $error)

(= (codex:environment-selection-unknown-id-error $environment-id)
   (codex:error-invalid-request
     (format-args "unknown turn environment id `{}`" ($environment-id))))

(= (codex:validate-environment-selections $environment-manager ())
   (codex:environment-selection-result-ok ()))

(= (codex:validate-environment-selections $environment-manager $environments)
   (let $head (list:first $environments)
     (let $environment-id
       (codex:turn-environment-selection-environment-id $head)
       (if (== (codex:environment-manager-get-environment
                 $environment-manager
                 $environment-id)
               CodexAbsent)
           (codex:environment-selection-result-err
             (codex:environment-selection-unknown-id-error $environment-id))
           (codex:validate-environment-selections
             $environment-manager
             (list:rest $environments))))))

(= (codex:selected-primary-environment $environment-manager ())
   (codex:environment-selection-result-ok CodexAbsent))

(= (codex:selected-primary-environment $environment-manager $environments)
   (let $head (list:first $environments)
     (let $environment-id
       (codex:turn-environment-selection-environment-id $head)
       (let $environment
         (codex:environment-manager-get-environment
           $environment-manager
           $environment-id)
         (if (== $environment CodexAbsent)
             (codex:environment-selection-result-err
               (codex:environment-selection-unknown-id-error $environment-id))
             (codex:environment-selection-result-ok $environment))))))
