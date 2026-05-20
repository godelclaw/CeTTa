; Rust-faithful installation id helper slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/installation_id.rs
; - uuid 1.20.0 parser forms used by Uuid::parse_str
;
; Covered in this increment:
; - INSTALLATION_ID_FILENAME
; - trim, parse, and canonicalize existing UUID file contents
; - resolve_installation_id's reuse-vs-rewrite decision using an explicit
;   generated UUID value supplied by the runtime layer
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust creates the Codex home directory, opens the file read/write/create,
;   locks it, enforces Unix mode 0644, generates Uuid::new_v4(), truncates,
;   writes, flushes, and syncs. CeTTa currently has no file locking,
;   chmod, sync, or UUID generation API at this layer, so this slice exposes
;   the same deterministic branch logic over explicit contents and generated
;   UUID inputs. The generated UUID argument has the same validity precondition
;   as Rust's Uuid::new_v4().to_string(). A future runtime wrapper must
;   preserve the Rust side effects.

!(import! &self str)

(= (codex:installation-id-filename)
   "installation_id")

(= (codex:installation-id-ascii-lower-char $char)
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

(= (codex:installation-id-ascii-lower-text $text)
   (if (== (str-length $text) 0)
       ""
       (str-concat
         (codex:installation-id-ascii-lower-char (str-slice $text 0 1))
         (codex:installation-id-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:installation-id-starts-with $text $prefix)
   (let $text-len (str-length $text)
     (let $prefix-len (str-length $prefix)
       (if (< $text-len $prefix-len)
           False
           (== (str-slice $text 0 $prefix-len) $prefix)))))

(= (codex:installation-id-is-ascii-hex-char $char)
   (let $found (str-find "0123456789abcdefABCDEF" $char)
     (if (== $found Empty) False True)))

(= (codex:installation-id-are-ascii-hex-chars-from $text $index)
   (if (== $index (str-length $text))
       True
       (if (codex:installation-id-is-ascii-hex-char
             (str-slice $text $index (+ $index 1)))
           (codex:installation-id-are-ascii-hex-chars-from
             $text
             (+ $index 1))
           False)))

(= (codex:installation-id-are-ascii-hex-chars $text)
   (codex:installation-id-are-ascii-hex-chars-from $text 0))

(= (codex:installation-id-simple-to-hyphenated $simple)
   (str-concat
     (str-slice $simple 0 8)
     (str-concat
       "-"
       (str-concat
         (str-slice $simple 8 12)
         (str-concat
           "-"
           (str-concat
             (str-slice $simple 12 16)
             (str-concat
               "-"
               (str-concat
                 (str-slice $simple 16 20)
                 (str-concat
                   "-"
                   (str-slice $simple 20 32))))))))))

(= (codex:installation-id-hyphenated-to-simple $text)
   (str-concat
     (str-slice $text 0 8)
     (str-concat
       (str-slice $text 9 13)
       (str-concat
         (str-slice $text 14 18)
         (str-concat
           (str-slice $text 19 23)
           (str-slice $text 24 36))))))

(= (codex:installation-id-is-hyphenated-shape $text)
   (if (== (str-length $text) 36)
       (and
         (== (str-slice $text 8 9) "-")
         (and
           (== (str-slice $text 13 14) "-")
           (and
             (== (str-slice $text 18 19) "-")
             (== (str-slice $text 23 24) "-"))))
       False))

(= (codex:installation-id-canonicalize-simple $text)
   (if (and
         (== (str-length $text) 32)
         (codex:installation-id-are-ascii-hex-chars $text))
       (codex:installation-id-simple-to-hyphenated
         (codex:installation-id-ascii-lower-text $text))
       CodexAbsent))

(= (codex:installation-id-canonicalize-hyphenated $text)
   (if (codex:installation-id-is-hyphenated-shape $text)
       (codex:installation-id-canonicalize-simple
         (codex:installation-id-hyphenated-to-simple $text))
       CodexAbsent))

(= (codex:installation-id-canonicalize-braced $text)
   (if (and
         (== (str-length $text) 38)
         (and
           (== (str-slice $text 0 1) "{")
           (== (str-slice $text 37 38) "}")))
       (codex:installation-id-canonicalize-hyphenated
         (str-slice $text 1 37))
       CodexAbsent))

(= (codex:installation-id-canonicalize-urn $text)
   (if (and
         (== (str-length $text) 45)
         (codex:installation-id-starts-with $text "urn:uuid:"))
       (codex:installation-id-canonicalize-hyphenated
         (str-slice $text 9 45))
       CodexAbsent))

(= (codex:installation-id-canonicalize-uuid $text)
   (let $len (str-length $text)
     (if (== $len 32)
         (codex:installation-id-canonicalize-simple $text)
         (if (== $len 36)
             (codex:installation-id-canonicalize-hyphenated $text)
             (if (== $len 38)
                 (codex:installation-id-canonicalize-braced $text)
                 (if (== $len 45)
                     (codex:installation-id-canonicalize-urn $text)
                     CodexAbsent))))))

(= (codex:installation-id-parse-existing $contents)
   (let $trimmed (str-trim $contents)
     (if (== $trimmed "")
         CodexAbsent
         (codex:installation-id-canonicalize-uuid $trimmed))))

(= (codex:installation-id-resolution-action
      (CodexInstallationIdReuse $uuid))
   "reuse")

(= (codex:installation-id-resolution-action
      (CodexInstallationIdWrite $uuid))
   "write")

(= (codex:installation-id-resolution-id
      (CodexInstallationIdReuse $uuid))
   $uuid)

(= (codex:installation-id-resolution-id
      (CodexInstallationIdWrite $uuid))
   $uuid)

(= (codex:installation-id-resolution-should-write
      (CodexInstallationIdReuse $uuid))
   False)

(= (codex:installation-id-resolution-should-write
      (CodexInstallationIdWrite $uuid))
   True)

(= (codex:resolve-installation-id-from-contents $contents $generated-uuid)
   (let $existing (codex:installation-id-parse-existing $contents)
     (if (== $existing CodexAbsent)
         (CodexInstallationIdWrite
           (codex:installation-id-canonicalize-uuid
             (str-trim $generated-uuid)))
         (CodexInstallationIdReuse $existing))))
