; Runtime read-deny matcher slice for the restarted Codex port.
;
; This ports the adjacent Rust helper tranche from:
; - openai-codex/codex-rs/protocol/src/permissions.rs
;   - ReadDenyMatcher
;   - ReadDenyMatcher::new
;   - ReadDenyMatcher::is_read_denied
;
; Required CeTTa deviations for audit:
; - Rust stores exact deny roots as `Vec<Vec<PathBuf>>` plus compiled
;   `globset::GlobMatcher` values. This restart slice stores a flattened,
;   deduplicated deny-root candidate list plus normalized deny glob strings.
;   The membership check is equivalent for the public helper behavior because
;   exact-root denial is still an `any(path_candidate starts_with denied_root)`
;   predicate.
; - Rust uses `Path::canonicalize()` plus `globset::GlobBuilder` with
;   `literal_separator(true)` and `allow_unclosed_class(true)`. CeTTa has no
;   native equivalent runtime, so this slice uses `/usr/bin/realpath` for the
;   existing-path canonical target and a narrow runtime Python matcher that
;   preserves the same visible literal-separator, `**`, `?`, character-class,
;   and literal-unclosed-`[` behavior covered by the adjacent Rust tests.

!(import! &self list)
!(import! &self path)
!(import! &self permissions)
!(import! &self process)
!(import! &self str)

(= (codex:read-deny-matcher
      $denied-candidates
      $deny-read-globs
      $invalid-pattern)
   (CodexReadDenyMatcher
     $denied-candidates
     $deny-read-globs
     $invalid-pattern))

(= (codex:read-deny-matcher-denied-candidates
      (CodexReadDenyMatcher
        $denied-candidates
        $deny-read-globs
        $invalid-pattern))
   $denied-candidates)

(= (codex:read-deny-matcher-deny-read-globs
      (CodexReadDenyMatcher
        $denied-candidates
        $deny-read-globs
        $invalid-pattern))
   $deny-read-globs)

(= (codex:read-deny-matcher-invalid-pattern
      (CodexReadDenyMatcher
        $denied-candidates
        $deny-read-globs
        $invalid-pattern))
   $invalid-pattern)

(= (codex:permissions-existing-canonical-path $path)
   (let $result
     (process-run-cmd-cwd-env-timeout-cap-bytes
       ("/usr/bin/realpath" "--" $path)
       (codex:permissions-helper-cwd)
       ()
       (codex:permissions-helper-timeout-ms)
       (codex:permissions-helper-max-bytes))
     (if (== (process-result-exit-code $result) 0)
         (path-normalize (str-trim (process-result-stdout $result)))
         CodexAbsent)))

(= (codex:permissions-normalized-and-canonical-candidates $path)
   (let $normalized
     (if (path-is-absolute? $path)
         (path-normalize $path)
         $path)
     (let $canonical
       (codex:permissions-existing-canonical-path $path)
       (if (== $canonical CodexAbsent)
           ($normalized)
           (codex:permissions-dedup-absolute-paths
             ($normalized $canonical)
             False)))))

(= (codex:read-deny-matcher-root-candidates ())
   ())

(= (codex:read-deny-matcher-root-candidates $roots)
   (let ($head $tail) (decons-atom $roots)
     (codex:permissions-dedup-absolute-paths
       (list:append
         (codex:permissions-normalized-and-canonical-candidates $head)
         (codex:read-deny-matcher-root-candidates $tail))
       False)))

(= (codex:permissions-deny-glob-helper-program)
   "import os\nimport re\nimport sys\n\npatterns = os.environ.get('CODEX_PERMISSION_PATTERNS', '').splitlines()\npaths = os.environ.get('CODEX_PERMISSION_PATHS', '').splitlines()\n\ndef component_to_regex(component: str):\n    out = []\n    i = 0\n    while i < len(component):\n        ch = component[i]\n        if ch == '*':\n            if i + 1 < len(component) and component[i + 1] == '*':\n                return None\n            out.append('[^/]*')\n            i += 1\n        elif ch == '?':\n            out.append('[^/]')\n            i += 1\n        elif ch == '[':\n            j = i + 1\n            while j < len(component) and component[j] != ']':\n                j += 1\n            if j >= len(component):\n                out.append(re.escape('['))\n                i += 1\n                continue\n            content = component[i + 1:j]\n            if content == '':\n                out.append(re.escape('[]'))\n                i = j + 1\n                continue\n            negate = content.startswith('!')\n            if negate:\n                content = content[1:]\n            cls = []\n            for idx, class_ch in enumerate(content):\n                if class_ch == '\\\\':\n                    cls.append('\\\\\\\\')\n                elif idx == 0 and class_ch == '^':\n                    cls.append('\\\\^')\n                else:\n                    cls.append(class_ch)\n            out.append('[' + ('^' if negate else '') + ''.join(cls) + ']')\n            i = j + 1\n        else:\n            out.append(re.escape(ch))\n            i += 1\n    return ''.join(out)\n\ndef translate(pattern: str):\n    absolute = pattern.startswith('/')\n    components = pattern.split('/')\n    if absolute:\n        components = components[1:]\n    regex = ['^']\n    if absolute:\n        regex.append('/')\n    prev_globstar = False\n    for index, component in enumerate(components):\n        if component == '' and index == len(components) - 1:\n            continue\n        if component == '**':\n            if not ''.join(regex).endswith('/'):\n                regex.append('/')\n            if index == len(components) - 1:\n                regex.append('(?:[^/]+(?:/[^/]+)*)?')\n            else:\n                regex.append('(?:[^/]+/)*')\n            prev_globstar = True\n            continue\n        if '**' in component:\n            return None\n        translated = component_to_regex(component)\n        if translated is None:\n            return None\n        if index > 0 and (not prev_globstar) and (not ''.join(regex).endswith('/')):\n            regex.append('/')\n        regex.append(translated)\n        prev_globstar = False\n    regex.append('$')\n    return ''.join(regex)\n\ncompiled = []\nfor pattern in patterns:\n    regex = translate(pattern)\n    if regex is None:\n        print('invalid')\n        sys.exit(0)\n    compiled.append(re.compile(regex))\n\nfor candidate in paths:\n    for matcher in compiled:\n        if matcher.match(candidate):\n            print('match')\n            sys.exit(0)\n\nprint('no_match')\n")

(= (codex:permissions-deny-glob-match-state () $paths)
   "no_match")

(= (codex:permissions-deny-glob-match-state $patterns $paths)
   (let $result
     (process-run-cmd-cwd-env-timeout-cap-bytes
       ("/usr/bin/python3"
        "-c"
        (codex:permissions-deny-glob-helper-program))
       (codex:permissions-helper-cwd)
       ((Env "CODEX_PERMISSION_PATTERNS" (str-join "\n" $patterns))
        (Env "CODEX_PERMISSION_PATHS" (str-join "\n" $paths)))
       (codex:permissions-helper-timeout-ms)
       (codex:permissions-helper-max-bytes))
     (if (== (process-result-exit-code $result) 0)
         (str-trim (process-result-stdout $result))
         "invalid")))

(= (codex:read-deny-matcher-new $file-system-sandbox-policy $cwd)
   (if (codex:file-system-sandbox-policy-has-denied-read-restrictions
         $file-system-sandbox-policy)
       (let $deny-read-globs
         (codex:file-system-sandbox-policy-get-unreadable-globs-with-cwd
           $file-system-sandbox-policy
           $cwd)
         (codex:read-deny-matcher
           (codex:read-deny-matcher-root-candidates
             (codex:file-system-sandbox-policy-get-unreadable-roots-with-cwd
               $file-system-sandbox-policy
               $cwd))
           $deny-read-globs
           (== (codex:permissions-deny-glob-match-state $deny-read-globs ())
               "invalid")))
       CodexAbsent))

(= (codex:read-deny-matcher-any-path-candidate-matches-root () $path-candidates)
   False)

(= (codex:read-deny-matcher-any-path-candidate-matches-root
      $denied-roots
      $path-candidates)
   (let ($head $tail) (decons-atom $denied-roots)
     (if (codex:read-deny-matcher-path-candidates-match-root
           $path-candidates
           $head)
         True
         (codex:read-deny-matcher-any-path-candidate-matches-root
           $tail
           $path-candidates))))

(= (codex:read-deny-matcher-path-candidates-match-root () $root)
   False)

(= (codex:read-deny-matcher-path-candidates-match-root $path-candidates $root)
   (let ($head $tail) (decons-atom $path-candidates)
     (if (or (== $head $root)
             (codex:permissions-path-starts-with-path $head $root))
         True
         (codex:read-deny-matcher-path-candidates-match-root $tail $root))))

(= (codex:read-deny-matcher-is-read-denied
      (CodexReadDenyMatcher
        $denied-candidates
        $deny-read-globs
        True)
      $path)
   True)

(= (codex:read-deny-matcher-is-read-denied
      (CodexReadDenyMatcher
        $denied-candidates
        $deny-read-globs
        False)
      $path)
   (let $path-candidates
     (codex:permissions-normalized-and-canonical-candidates $path)
     (if (codex:read-deny-matcher-any-path-candidate-matches-root
           $denied-candidates
           $path-candidates)
         True
         (== (codex:permissions-deny-glob-match-state
               $deny-read-globs
               $path-candidates)
             "match"))))

(= (codex:read-deny-matcher-option-is-read-denied CodexAbsent $path)
   False)

(= (codex:read-deny-matcher-option-is-read-denied
      (CodexReadDenyMatcher
        $denied-candidates
        $deny-read-globs
        $invalid-pattern)
      $path)
   (codex:read-deny-matcher-is-read-denied
     (CodexReadDenyMatcher
       $denied-candidates
       $deny-read-globs
       $invalid-pattern)
     $path))

(= (codex:file-system-sandbox-policy-is-read-denied-with-cwd
      $file-system-sandbox-policy
      $path
      $cwd)
   (once
     (let $matcher
       (codex:read-deny-matcher-new
         $file-system-sandbox-policy
         $cwd)
       (codex:read-deny-matcher-option-is-read-denied
         $matcher
         $path))))
