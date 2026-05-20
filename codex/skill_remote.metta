; Narrow Rust-faithful remote skill helper slice.
;
; This ports the pure helper behavior from:
; - openai-codex/codex-rs/core-skills/src/remote.rs
;
; Covered in this increment:
; - remote skill scope and product-surface query values
; - remote skill summary/download result shapes
; - codex-backend auth precondition result
; - list/export request URL and query parameter construction
; - zip payload signature detection
; - safe relative path join validation for zip entries
; - zip entry name normalization with prefix stripping
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust performs HTTP requests and zip extraction with reqwest/tokio/zip. This
;   CeTTa slice ports only the deterministic values and validation helpers at
;   that boundary; network and archive IO remain separate runtime-library work.
; - Rust `is_zip_payload` accepts a byte slice. This pure surface represents
;   bytes as a list of integer byte values and applies the same prefix tests.
; - Rust `safe_join` validates `std::path::Component::Normal` components and
;   returns `base.join(name)`. This CeTTa helper mirrors the Linux-visible
;   component acceptance used by the target environment and returns a path
;   string that preserves the supplied relative entry text after the base.

!(import! &self list)
!(import! &self str)
!(import! &self login_auth)

(= (codex:remote-skills-api-timeout-secs)
   30)

(= (codex:remote-skill-scope-workspace-shared)
   (CodexRemoteSkillScopeWorkspaceShared))

(= (codex:remote-skill-scope-all-shared)
   (CodexRemoteSkillScopeAllShared))

(= (codex:remote-skill-scope-personal)
   (CodexRemoteSkillScopePersonal))

(= (codex:remote-skill-scope-example)
   (CodexRemoteSkillScopeExample))

(= (codex:remote-skill-product-surface-chatgpt)
   (CodexRemoteSkillProductSurfaceChatgpt))

(= (codex:remote-skill-product-surface-codex)
   (CodexRemoteSkillProductSurfaceCodex))

(= (codex:remote-skill-product-surface-api)
   (CodexRemoteSkillProductSurfaceApi))

(= (codex:remote-skill-product-surface-atlas)
   (CodexRemoteSkillProductSurfaceAtlas))

(= (codex:remote-skill-summary $id $name $description)
   (CodexRemoteSkillSummary $id $name $description))

(= (codex:remote-skill-summary-id
      (CodexRemoteSkillSummary $id $name $description))
   $id)

(= (codex:remote-skill-summary-name
      (CodexRemoteSkillSummary $id $name $description))
   $name)

(= (codex:remote-skill-summary-description
      (CodexRemoteSkillSummary $id $name $description))
   $description)

(= (codex:remote-skill-download-result $id $path)
   (CodexRemoteSkillDownloadResult $id $path))

(= (codex:remote-skill-download-result-id
      (CodexRemoteSkillDownloadResult $id $path))
   $id)

(= (codex:remote-skill-download-result-path
      (CodexRemoteSkillDownloadResult $id $path))
   $path)

(= (codex:remote-skill-query-param $name $value)
   (CodexRemoteSkillQueryParam $name $value))

(= (codex:remote-skill-list-request $url $query-params)
   (CodexRemoteSkillListRequest $url $query-params))

(= (codex:remote-skill-list-request-url
      (CodexRemoteSkillListRequest $url $query-params))
   $url)

(= (codex:remote-skill-list-request-query-params
      (CodexRemoteSkillListRequest $url $query-params))
   $query-params)

(= (codex:remote-skill-export-request $url $output-dir)
   (CodexRemoteSkillExportRequest $url $output-dir))

(= (codex:remote-skill-export-request-url
      (CodexRemoteSkillExportRequest $url $output-dir))
   $url)

(= (codex:remote-skill-export-request-output-dir
      (CodexRemoteSkillExportRequest $url $output-dir))
   $output-dir)

(= (codex:remote-skill-ok $value)
   (CodexRemoteSkillOk $value))

(= (codex:remote-skill-err $message)
   (CodexRemoteSkillErr $message))

(= (codex:remote-skill-as-query-scope $scope)
   (case $scope
     (((CodexRemoteSkillScopeWorkspaceShared) "workspace-shared")
      ((CodexRemoteSkillScopeAllShared) "all-shared")
      ((CodexRemoteSkillScopePersonal) "personal")
      ((CodexRemoteSkillScopeExample) "example"))))

(= (codex:remote-skill-as-query-product-surface $product-surface)
   (case $product-surface
     (((CodexRemoteSkillProductSurfaceChatgpt) "chatgpt")
      ((CodexRemoteSkillProductSurfaceCodex) "codex")
      ((CodexRemoteSkillProductSurfaceApi) "api")
      ((CodexRemoteSkillProductSurfaceAtlas) "atlas"))))

(= (codex:remote-skill-ensure-codex-backend-auth $auth)
   (case $auth
     ((CodexAbsent
       (codex:remote-skill-err
         "chatgpt authentication required for remote skill scopes"))
      ($present-auth
       (if (codex:codex-auth-uses-codex-backend $present-auth)
           (codex:remote-skill-ok $present-auth)
           (codex:remote-skill-err
             "chatgpt authentication required for remote skill scopes; api key auth is not supported"))))))

(= (codex:remote-skill-text-starts-with $text $prefix)
   (case (str-find $text $prefix)
     ((0 True)
      ($other False))))

(= (codex:remote-skill-text-ends-with $text $suffix)
   (let $text-len (str-length $text)
     (let $suffix-len (str-length $suffix)
       (if (< $text-len $suffix-len)
           False
           (== (str-slice $text (- $text-len $suffix-len) $text-len)
               $suffix)))))

(= (codex:remote-skill-trim-end-slashes $text)
   (if (codex:remote-skill-text-ends-with $text "/")
       (codex:remote-skill-trim-end-slashes
         (str-slice $text 0 (- (str-length $text) 1)))
       $text))

(= (codex:remote-skill-strip-prefix $text $prefix)
   (if (codex:remote-skill-text-starts-with $text $prefix)
       (str-slice $text (str-length $prefix) (str-length $text))
       CodexAbsent))

(= (codex:remote-skill-base-join-preserve $base $name)
   (if (== $base "")
       $name
       (if (== $name "")
           $base
           (if (codex:remote-skill-text-ends-with $base "/")
               (str-concat $base $name)
               (str-concat $base (str-concat "/" $name))))))

(= (codex:remote-skill-list-enabled-query-param CodexAbsent)
   ())

(= (codex:remote-skill-list-enabled-query-param True)
   ((codex:remote-skill-query-param "enabled" "true")))

(= (codex:remote-skill-list-enabled-query-param False)
   ((codex:remote-skill-query-param "enabled" "false")))

(= (codex:remote-skill-list-query-params
      $scope
      $product-surface
      $enabled)
   (list:append
     ((codex:remote-skill-query-param
        "product_surface"
        (codex:remote-skill-as-query-product-surface $product-surface))
      (codex:remote-skill-query-param
        "scope"
        (codex:remote-skill-as-query-scope $scope)))
     (codex:remote-skill-list-enabled-query-param $enabled)))

(= (codex:remote-skill-list-request-from-parts
      $chatgpt-base-url
      $scope
      $product-surface
      $enabled)
   (let $base-url (codex:remote-skill-trim-end-slashes $chatgpt-base-url)
     (codex:remote-skill-list-request
       (str-concat $base-url "/hazelnuts")
       (codex:remote-skill-list-query-params
         $scope
         $product-surface
         $enabled))))

(= (codex:remote-skill-export-output-dir $codex-home $skill-id)
   (codex:remote-skill-base-join-preserve
     (codex:remote-skill-base-join-preserve $codex-home "skills")
     $skill-id))

(= (codex:remote-skill-export-request-from-parts
      $chatgpt-base-url
      $codex-home
      $skill-id)
   (let $base-url (codex:remote-skill-trim-end-slashes $chatgpt-base-url)
     (codex:remote-skill-export-request
       (str-concat
         $base-url
         (str-concat "/hazelnuts/" (str-concat $skill-id "/export")))
       (codex:remote-skill-export-output-dir $codex-home $skill-id))))

(= (codex:remote-skill-byte-list-starts-with $bytes $prefix)
   (case $prefix
     ((() True)
      ($non-empty-prefix
       (case $bytes
         ((() False)
          ($non-empty-bytes
           (let $byte (list:first $non-empty-bytes)
             (let $prefix-byte (list:first $non-empty-prefix)
               (if (== $byte $prefix-byte)
                   (codex:remote-skill-byte-list-starts-with
                     (list:rest $non-empty-bytes)
                     (list:rest $non-empty-prefix))
                  False))))))))))

(= (codex:is-remote-skill-zip-payload $bytes)
   (if (codex:remote-skill-byte-list-starts-with $bytes (80 75 3 4))
       True
       (if (codex:remote-skill-byte-list-starts-with $bytes (80 75 5 6))
           True
           (if (codex:remote-skill-byte-list-starts-with $bytes (80 75 7 8))
               True
               False))))

(= (codex:remote-skill-invalid-path-message $name)
   (format-args "Invalid file path in remote skill payload: {}" ($name)))

(= (codex:remote-skill-safe-path-segments ())
   True)

(= (codex:remote-skill-safe-path-segments $segments)
   (let $head (list:first $segments)
     (let $tail (list:rest $segments)
       (if (== $head "..")
           False
           (codex:remote-skill-safe-path-segments $tail)))))

(= (codex:remote-skill-safe-relative-path $name)
   (if (== $name ".")
       False
       (if (codex:remote-skill-text-starts-with $name "./")
           False
           (if (codex:remote-skill-text-starts-with $name "/")
               False
               (codex:remote-skill-safe-path-segments
                 (str-split "/" $name))))))

(= (codex:remote-skill-safe-join $base $name)
   (if (codex:remote-skill-safe-relative-path $name)
       (codex:remote-skill-ok
         (codex:remote-skill-base-join-preserve $base $name))
       (codex:remote-skill-err
         (codex:remote-skill-invalid-path-message $name))))

(= (codex:remote-skill-trim-start-dot-slash $name)
   (if (codex:remote-skill-text-starts-with $name "./")
       (codex:remote-skill-trim-start-dot-slash
         (str-slice $name 2 (str-length $name)))
       $name))

(= (codex:remote-skill-strip-prefix-candidates $trimmed ())
   $trimmed)

(= (codex:remote-skill-strip-prefix-candidates $trimmed $prefix-candidates)
   (let $prefix (list:first $prefix-candidates)
     (let $tail (list:rest $prefix-candidates)
       (if (== $prefix "")
           (codex:remote-skill-strip-prefix-candidates $trimmed $tail)
           (let $prefix-with-slash (str-concat $prefix "/")
             (case
               (codex:remote-skill-strip-prefix $trimmed $prefix-with-slash)
               ((CodexAbsent
                 (codex:remote-skill-strip-prefix-candidates
                   $trimmed
                   $tail))
                ($rest $rest))))))))

(= (codex:remote-skill-normalize-zip-name $name $prefix-candidates)
   (let $trimmed (codex:remote-skill-trim-start-dot-slash $name)
     (let $normalized
       (codex:remote-skill-strip-prefix-candidates
         $trimmed
         $prefix-candidates)
       (if (== $normalized "")
           CodexAbsent
           $normalized))))
