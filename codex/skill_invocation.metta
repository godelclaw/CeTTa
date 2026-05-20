; Narrow Rust-faithful core-skills invocation slice.
;
; This ports:
; - openai-codex/codex-rs/core-skills/src/invocation_utils.rs
; - openai-codex/codex-rs/core-skills/src/env_var_dependencies.rs
;
; Covered in this increment:
; - implicit skill path index construction for `scripts/` and `SKILL.md`
; - command tokenization for implicit invocation detection
; - script-run detection with the Rust runner and extension allow-lists
; - skill-doc read detection with the Rust file-reader allow-list
; - top-level implicit skill invocation detection
; - environment variable dependency collection from mentioned skills
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `HashMap<AbsolutePathBuf, SkillMetadata>`. This CeTTa surface
;   uses first-match list indexes. The builder prepends entries while scanning
;   left-to-right, so duplicate paths resolve to the last skill, matching
;   Rust `HashMap::insert` overwrite behavior.
; - Rust `canonicalize_if_exists()` follows the filesystem when a path exists.
;   This pure CeTTa slice applies lexical `path-normalize` after `path-join`.
;   That preserves the visible non-symlink path behavior covered here, but does
;   not resolve symlinks until a broader filesystem canonicalization layer is
;   available at this boundary.
; - Rust tokenizes with `shlex::split` and falls back to whitespace splitting
;   on parse failure. CeTTa reuses the native shell literal-command parser
;   through a `bash -lc` wrapper and falls back to `str-split-whitespace` when
;   the parser rejects the command. The visible argv behavior for the supported
;   invocation forms is the same.

!(import! &self list)
!(import! &self path)
!(import! &self shell)
!(import! &self str)

(= (codex:skill-path-index-entry $path $skill)
   (CodexSkillPathIndexEntry $path $skill))

(= (codex:skill-path-index-entry-path
      (CodexSkillPathIndexEntry $path $skill))
   $path)

(= (codex:skill-path-index-entry-skill
      (CodexSkillPathIndexEntry $path $skill))
   $skill)

(= (codex:implicit-skill-path-indexes $by-scripts-dir $by-skill-doc-path)
   (CodexImplicitSkillPathIndexes $by-scripts-dir $by-skill-doc-path))

(= (codex:implicit-skill-path-indexes-by-scripts-dir
      (CodexImplicitSkillPathIndexes $by-scripts-dir $by-skill-doc-path))
   $by-scripts-dir)

(= (codex:implicit-skill-path-indexes-by-skill-doc-path
      (CodexImplicitSkillPathIndexes $by-scripts-dir $by-skill-doc-path))
   $by-skill-doc-path)

(= (codex:skill-load-outcome $implicit-skills-by-scripts-dir $implicit-skills-by-doc-path)
   (CodexSkillLoadOutcome
     $implicit-skills-by-scripts-dir
     $implicit-skills-by-doc-path))

(= (codex:skill-load-outcome-implicit-skills-by-scripts-dir
      (CodexSkillLoadOutcome $implicit-skills-by-scripts-dir $implicit-skills-by-doc-path))
   $implicit-skills-by-scripts-dir)

(= (codex:skill-load-outcome-implicit-skills-by-doc-path
      (CodexSkillLoadOutcome $implicit-skills-by-scripts-dir $implicit-skills-by-doc-path))
   $implicit-skills-by-doc-path)

(= (codex:skill-metadata-name
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $name)

(= (codex:skill-metadata-dependencies
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $dependencies)

(= (codex:skill-metadata-path
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $path)

(= (codex:skill-dependencies-tools (CodexSkillDependencies $tools))
   $tools)

(= (codex:skill-tool-dependency-type
      (CodexSkillToolDependency
        $type
        $value
        $description
        $transport
        $command
        $url))
   $type)

(= (codex:skill-tool-dependency-value
      (CodexSkillToolDependency
        $type
        $value
        $description
        $transport
        $command
        $url))
   $value)

(= (codex:skill-tool-dependency-description
      (CodexSkillToolDependency
        $type
        $value
        $description
        $transport
        $command
        $url))
   $description)

(= (codex:skill-dependency-info $skill-name $name $description)
   (CodexSkillDependencyInfo $skill-name $name $description))

(= (codex:skill-dependency-info-skill-name
      (CodexSkillDependencyInfo $skill-name $name $description))
   $skill-name)

(= (codex:skill-dependency-info-name
      (CodexSkillDependencyInfo $skill-name $name $description))
   $name)

(= (codex:skill-dependency-info-description
      (CodexSkillDependencyInfo $skill-name $name $description))
   $description)

(= (codex:skill-invocation-ascii-lower-char $char)
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

(= (codex:skill-invocation-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:skill-invocation-ascii-lower-char (str-slice $text 0 1))
         (codex:skill-invocation-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:skill-invocation-strip-exe-suffix $runner)
   (if (str-ends-with? $runner ".exe")
       (str-slice $runner 0 (- (str-length $runner) 4))
       $runner))

(= (codex:skill-invocation-command-basename $command)
   (let $parts (path-parts $command)
     (if (== $parts ())
         $command
         (list:first (list:reverse $parts)))))

(= (codex:is-skill-invocation-runner $runner)
   (case $runner
     (("python" True)
      ("python3" True)
      ("bash" True)
      ("zsh" True)
      ("sh" True)
      ("node" True)
      ("deno" True)
      ("ruby" True)
      ("perl" True)
      ("pwsh" True)
      ($other False))))

(= (codex:is-skill-invocation-script-token $token)
   (let $lower (codex:skill-invocation-ascii-lower-text $token)
     (if (str-ends-with? $lower ".py")
         True
         (if (str-ends-with? $lower ".sh")
             True
             (if (str-ends-with? $lower ".js")
                 True
                 (if (str-ends-with? $lower ".ts")
                     True
                     (if (str-ends-with? $lower ".rb")
                         True
                         (if (str-ends-with? $lower ".pl")
                             True
                             (if (str-ends-with? $lower ".ps1")
                                 True
                                 False)))))))))

(= (codex:skill-invocation-first-script-arg ())
   CodexAbsent)

(= (codex:skill-invocation-first-script-arg $tokens)
   (let $head (list:first $tokens)
     (let $tail (list:rest $tokens)
       (if (== $head "--")
           (codex:skill-invocation-first-script-arg $tail)
           (if (str-starts-with? $head "-")
               (codex:skill-invocation-first-script-arg $tail)
               $head)))))

(= (codex:script-run-token ())
   CodexAbsent)

(= (codex:script-run-token $tokens)
   (let $runner-token (list:first $tokens)
     (let $runner
       (codex:skill-invocation-strip-exe-suffix
         (codex:skill-invocation-ascii-lower-text
           (codex:skill-invocation-command-basename $runner-token)))
       (if (not (codex:is-skill-invocation-runner $runner))
           CodexAbsent
           (case (codex:skill-invocation-first-script-arg (list:rest $tokens))
             ((CodexAbsent CodexAbsent)
              ($script-token
               (if (codex:is-skill-invocation-script-token $script-token)
                   $script-token
                   CodexAbsent))))))))

(= (codex:is-skill-invocation-file-reader $program)
   (case $program
     (("cat" True)
      ("sed" True)
      ("head" True)
      ("tail" True)
      ("less" True)
      ("more" True)
      ("bat" True)
      ("awk" True)
      ($other False))))

(= (codex:command-reads-file ())
   False)

(= (codex:command-reads-file $tokens)
   (let $program
     (codex:skill-invocation-ascii-lower-text
       (codex:skill-invocation-command-basename (list:first $tokens)))
     (codex:is-skill-invocation-file-reader $program)))

(= (codex:skill-invocation-canonicalize-if-exists $path)
   (path-normalize $path))

(= (codex:skill-invocation-tokenize-command $command)
   (case (shell-plain-commands (shell-shlex-join ("bash" "-lc" $command)))
     ((Empty (str-split-whitespace $command))
      ($commands
       (if (== $commands ())
           ()
           (list:first $commands))))))

(= (codex:skill-invocation-path-ancestors $path)
   (let $normalized (path-normalize $path)
     (let $parent (path-dirname $normalized)
       (if (== $parent $normalized)
           ($normalized)
           (cons-atom
             $normalized
             (codex:skill-invocation-path-ancestors $parent))))))

(= (codex:skill-path-index-lookup () $path)
   CodexAbsent)

(= (codex:skill-path-index-lookup $entries $path)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:skill-path-index-entry-path $head) $path)
           (codex:skill-path-index-entry-skill $head)
           (codex:skill-path-index-lookup $tail $path)))))

(= (codex:skill-path-index-lookup-ancestors $entries ())
   CodexAbsent)

(= (codex:skill-path-index-lookup-ancestors $entries $ancestors)
   (let $head (list:first $ancestors)
     (let $tail (list:rest $ancestors)
       (case (codex:skill-path-index-lookup $entries $head)
         ((CodexAbsent
           (codex:skill-path-index-lookup-ancestors $entries $tail))
          ($skill $skill))))))

(= (codex:build-implicit-skill-path-indexes $skills)
   (codex:build-implicit-skill-path-indexes-acc $skills () ()))

(= (codex:build-implicit-skill-path-indexes-acc () $by-scripts-dir $by-skill-doc-path)
   (codex:implicit-skill-path-indexes $by-scripts-dir $by-skill-doc-path))

(= (codex:build-implicit-skill-path-indexes-acc $skills $by-scripts-dir $by-skill-doc-path)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $skill-doc-path
         (codex:skill-invocation-canonicalize-if-exists
           (codex:skill-metadata-path $skill))
         (let $skill-dir (path-dirname (codex:skill-metadata-path $skill))
           (let $scripts-dir
             (codex:skill-invocation-canonicalize-if-exists
               (path-join $skill-dir "scripts"))
             (codex:build-implicit-skill-path-indexes-acc
               $tail
               (cons-atom
                 (codex:skill-path-index-entry $scripts-dir $skill)
                 $by-scripts-dir)
               (cons-atom
                 (codex:skill-path-index-entry $skill-doc-path $skill)
                 $by-skill-doc-path))))))))

(= (codex:skill-load-outcome-from-skills $skills)
   (let $indexes (codex:build-implicit-skill-path-indexes $skills)
     (codex:skill-load-outcome
       (codex:implicit-skill-path-indexes-by-scripts-dir $indexes)
       (codex:implicit-skill-path-indexes-by-skill-doc-path $indexes))))

(= (codex:detect-skill-script-run $outcome $tokens $workdir)
   (case (codex:script-run-token $tokens)
     ((CodexAbsent CodexAbsent)
      ($script-token
       (let $script-path
         (codex:skill-invocation-canonicalize-if-exists
           (path-join $workdir $script-token))
         (codex:skill-path-index-lookup-ancestors
           (codex:skill-load-outcome-implicit-skills-by-scripts-dir $outcome)
           (codex:skill-invocation-path-ancestors $script-path)))))))

(= (codex:skill-invocation-detect-doc-token $doc-index () $workdir)
   CodexAbsent)

(= (codex:skill-invocation-detect-doc-token $doc-index $tokens $workdir)
   (let $head (list:first $tokens)
     (let $tail (list:rest $tokens)
       (if (str-starts-with? $head "-")
           (codex:skill-invocation-detect-doc-token $doc-index $tail $workdir)
           (let $candidate-path
             (codex:skill-invocation-canonicalize-if-exists
               (path-join $workdir $head))
             (case (codex:skill-path-index-lookup $doc-index $candidate-path)
               ((CodexAbsent
                 (codex:skill-invocation-detect-doc-token
                   $doc-index
                   $tail
                   $workdir))
                ($skill $skill))))))))

(= (codex:detect-skill-doc-read $outcome $tokens $workdir)
   (if (not (codex:command-reads-file $tokens))
       CodexAbsent
       (codex:skill-invocation-detect-doc-token
         (codex:skill-load-outcome-implicit-skills-by-doc-path $outcome)
         (list:rest $tokens)
         $workdir)))

(= (codex:detect-implicit-skill-invocation-for-command $outcome $command $workdir)
   (let $canonical-workdir
     (codex:skill-invocation-canonicalize-if-exists $workdir)
     (let $tokens (codex:skill-invocation-tokenize-command $command)
       (case (codex:detect-skill-script-run $outcome $tokens $canonical-workdir)
         ((CodexAbsent
           (codex:detect-skill-doc-read $outcome $tokens $canonical-workdir))
          ($skill $skill))))))

(= (codex:skill-env-var-dependencies-for-tools $skill-name ())
   ())

(= (codex:skill-env-var-dependencies-for-tools $skill-name $tools)
   (let $tool (list:first $tools)
     (let $tail (list:rest $tools)
       (let $tail-dependencies
         (codex:skill-env-var-dependencies-for-tools $skill-name $tail)
         (if (not (== (codex:skill-tool-dependency-type $tool) "env_var"))
             $tail-dependencies
             (if (== (codex:skill-tool-dependency-value $tool) "")
                 $tail-dependencies
                 (cons-atom
                   (codex:skill-dependency-info
                     $skill-name
                     (codex:skill-tool-dependency-value $tool)
                     (codex:skill-tool-dependency-description $tool))
                   $tail-dependencies)))))))

(= (codex:skill-env-var-dependencies-for-skill $skill)
   (case (codex:skill-metadata-dependencies $skill)
     ((CodexAbsent ())
      ((CodexSkillDependencies $tools)
       (codex:skill-env-var-dependencies-for-tools
         (codex:skill-metadata-name $skill)
         $tools)))))

(= (codex:collect-env-var-dependencies ())
   ())

(= (codex:collect-env-var-dependencies $mentioned-skills)
   (let $skill (list:first $mentioned-skills)
     (let $tail (list:rest $mentioned-skills)
       (codex:skill-invocation-list-append
         (codex:skill-env-var-dependencies-for-skill $skill)
         (codex:collect-env-var-dependencies $tail)))))

(= (codex:skill-invocation-list-append () $rhs)
   $rhs)

(= (codex:skill-invocation-list-append $lhs $rhs)
   (let $head (list:first $lhs)
     (let $tail (list:rest $lhs)
       (case (codex:skill-invocation-list-append $tail $rhs)
         (($appended
           (cons-atom $head $appended)))))))
