; Rust-faithful shell detection helper slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/shell_detect.rs
;
; Covered in this increment:
; - detect_shell_type direct shell-name matching
; - recursive file_stem fallback for paths and extension-suffixed names
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust accepts `PathBuf`/`Path` and can carry non-UTF-8 OsStr values. CeTTa
;   paths are strings in the current runtime, so the non-UTF-8 `None` branch is
;   not representable in this pure slice.
; - Rust `Path::file_stem` is platform-specific. This slice follows the
;   Unix-like slash semantics used by the current CeTTa validation profile.

!(import! &self list)
!(import! &self session_shell)
!(import! &self str)

(= (codex:detect-shell-type-direct $shell-path)
   (if (== $shell-path "zsh")
       (codex:shell-type-zsh)
       (if (== $shell-path "sh")
           (codex:shell-type-sh)
           (if (== $shell-path "cmd")
               (codex:shell-type-cmd)
               (if (== $shell-path "bash")
                   (codex:shell-type-bash)
                   (if (== $shell-path "pwsh")
                       (codex:shell-type-powershell)
                       (if (== $shell-path "powershell")
                           (codex:shell-type-powershell)
                           CodexAbsent)))))))

(= (codex:shell-detect-last-non-empty-component () $fallback)
   $fallback)

(= (codex:shell-detect-last-non-empty-component $parts $fallback)
   (let $head (list:first $parts)
     (let $tail (list:rest $parts)
       (codex:shell-detect-last-non-empty-component
         $tail
         (if (== $head "")
             $fallback
             $head)))))

(= (codex:shell-detect-drop-last ())
   ())

(= (codex:shell-detect-drop-last $parts)
   (let $head (list:first $parts)
     (let $tail (list:rest $parts)
       (if (== $tail ())
           ()
           (let $rest (eval (codex:shell-detect-drop-last $tail))
             (cons-atom $head $rest))))))

(= (codex:shell-detect-strip-final-extension $component)
   (let $parts (str-split "." $component)
     (if (< (list:len $parts) 2)
         $component
         (if (and
               (== (list:first $parts) "")
               (== (list:len $parts) 2))
             $component
             (let $stem-parts
               (eval (codex:shell-detect-drop-last $parts))
               (str-join "." $stem-parts))))))

(= (codex:shell-detect-file-stem $shell-path)
   (let $component
     (codex:shell-detect-last-non-empty-component
       (str-split "/" $shell-path)
       CodexAbsent)
     (if (== $component CodexAbsent)
         CodexAbsent
         (codex:shell-detect-strip-final-extension $component))))

(= (codex:detect-shell-type $shell-path)
   (case (codex:detect-shell-type-direct $shell-path)
     ((CodexAbsent
       (let $shell-name (codex:shell-detect-file-stem $shell-path)
         (if (or
               (== $shell-name CodexAbsent)
               (== $shell-name $shell-path))
             CodexAbsent
             (codex:detect-shell-type $shell-name))))
      ($shell-type
       $shell-type))))
