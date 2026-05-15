; Narrow Rust-faithful session rollout init error mapper.
;
; This ports:
; - openai-codex/codex-rs/core/src/session_rollout_init_error.rs
;
; Covered in this increment:
; - rollout `SESSIONS_SUBDIR` constant mirror
; - io-kind-specific session-init hint mapping
; - first-mappable-io-cause scan over the error chain
; - fallback Fatal message when no mapped io cause exists
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust receives `&anyhow::Error` and walks `err.chain()`. The current CeTTa
;   port preserves the same visible first-mappable-cause behavior through an
;   explicit ordered cause list with io and non-io cause constructors.

!(import! &self error)
!(import! &self list)
!(import! &self path)
!(import! &self str)

(= (codex:sessions-subdir)
   "sessions")

(= (codex:io-error-kind-permission-denied)
   "permission_denied")

(= (codex:io-error-kind-not-found)
   "not_found")

(= (codex:io-error-kind-already-exists)
   "already_exists")

(= (codex:io-error-kind-invalid-data)
   "invalid_data")

(= (codex:io-error-kind-invalid-input)
   "invalid_input")

(= (codex:io-error-kind-is-a-directory)
   "is_a_directory")

(= (codex:io-error-kind-not-a-directory)
   "not_a_directory")

(= (codex:io-error-kind-other)
   "other")

(= (codex:io-error $kind $message)
   (CodexIoError $kind $message))

(= (codex:io-error-kind (CodexIoError $kind $message))
   $kind)

(= (codex:io-error-message (CodexIoError $kind $message))
   $message)

(= (codex:session-init-cause-io $io-error)
   (CodexSessionInitCauseIo $io-error))

(= (codex:session-init-cause-other $message)
   (CodexSessionInitCauseOther $message))

(= (codex:session-storage-path $codex-home)
   (path-join $codex-home (codex:sessions-subdir)))

(= (codex:map-rollout-io-error $io-error $codex-home)
   (let $sessions-dir (codex:session-storage-path $codex-home)
     (let $kind (codex:io-error-kind $io-error)
       (let $message (codex:io-error-message $io-error)
         (if (== $kind (codex:io-error-kind-permission-denied))
             (codex:error-fatal
               (str-concat
                 "Codex cannot access session files at "
                 (str-concat
                   $sessions-dir
                   (str-concat
                     " (permission denied). If sessions were created using sudo, fix ownership: sudo chown -R $(whoami) "
                     (str-concat
                       $codex-home
                       (str-concat
                         " (underlying error: "
                         (str-concat $message ")")))))))
             (if (== $kind (codex:io-error-kind-not-found))
                 (codex:error-fatal
                   (str-concat
                     "Session storage missing at "
                     (str-concat
                       $sessions-dir
                       (str-concat
                         ". Create the directory or choose a different Codex home. (underlying error: "
                         (str-concat $message ")")))))
                 (if (== $kind (codex:io-error-kind-already-exists))
                     (codex:error-fatal
                       (str-concat
                         "Session storage path "
                         (str-concat
                           $sessions-dir
                           (str-concat
                             " is blocked by an existing file. Remove or rename it so Codex can create sessions. (underlying error: "
                             (str-concat $message ")")))))
                     (if (or
                           (== $kind (codex:io-error-kind-invalid-data))
                           (== $kind (codex:io-error-kind-invalid-input)))
                         (codex:error-fatal
                           (str-concat
                             "Session data under "
                             (str-concat
                               $sessions-dir
                               (str-concat
                                 " looks corrupt or unreadable. Clearing the sessions directory may help (this will remove saved threads). (underlying error: "
                                 (str-concat $message ")")))))
                         (if (or
                               (== $kind (codex:io-error-kind-is-a-directory))
                               (== $kind (codex:io-error-kind-not-a-directory)))
                             (codex:error-fatal
                               (str-concat
                                 "Session storage path "
                                 (str-concat
                                   $sessions-dir
                                   (str-concat
                                     " has an unexpected type. Ensure it is a directory Codex can use for session files. (underlying error: "
                                     (str-concat $message ")")))))
                             CodexAbsent)))))))))

(= (codex:map-session-init-error-from-causes $display-message () $codex-home)
   (codex:error-fatal
     (str-concat "Failed to initialize session: " $display-message)))

(= (codex:map-session-init-error-from-causes $display-message $causes $codex-home)
   (let $head (list:first $causes)
     (let $tail (list:rest $causes)
       (case $head
         (((CodexSessionInitCauseIo $io-error)
           (let $mapped (codex:map-rollout-io-error $io-error $codex-home)
             (if (== $mapped CodexAbsent)
                 (codex:map-session-init-error-from-causes
                   $display-message
                   $tail
                   $codex-home)
                 $mapped)))
          ((CodexSessionInitCauseOther $message)
           (codex:map-session-init-error-from-causes
             $display-message
             $tail
             $codex-home)))))))

(= (codex:map-session-init-error $display-message $causes $codex-home)
   (codex:map-session-init-error-from-causes
     $display-message
     $causes
     $codex-home))
