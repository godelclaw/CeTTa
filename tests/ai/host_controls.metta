; Profile composition, experiment activation and budget observation through
; the real CLI. The parent stays in stable PeTTa extended.
!(import! &self (library proc))
!(import! &self (library str))
!(import! &self (library system))

(= (ah:environment)
   (("PATH" "/usr/local/bin:/usr/bin:/bin") ("LANG" "C.UTF-8")
    ("LC_ALL" "C.UTF-8") ("TZ" "UTC")))
(= (ah:check $binary $name $arguments $wanted)
   (case (proc:run (cons-atom $binary $arguments) "." (ah:environment) 15000 1048576)
     (((proc:exited 0 $actual "")
        (if (== $wanted $actual) ()
          (let $shown (println! (HostMismatch $name $wanted $actual)) (system:exit 1))))
      ($other (let $shown (println! (HostExecutionFailed $name $other)) (system:exit 1))))))
(= (ah:profile-source)
   "!(ai:experiment failure-values) !(let $x (Error first (Fault detail)) never) !(car-atom [1 2]) !(if (== r#\"a\\n\"# \"a\\\\n\") raw bad)")
(= (ah:profile $binary $language $first $second)
   (let* (($source (ah:profile-source))
          ($wanted (if (== $language "he")
            "[(Error first (Fault detail))]\n[1]\n[raw]\n"
            "()\n(Error first (Fault detail))\n1\nraw\n")))
     (ah:check $binary (Profiles $language $first $second)
       ("--lang" $language "--profile" $first "--profile" $second "-e" $source) $wanted)))
(= (ah:reject $binary $arguments)
   (case (proc:run (cons-atom $binary $arguments) "." (ah:environment) 15000 1048576)
     (((proc:exited 2 "" "error: ai currently composes with the default or extended profile\n") ())
      ($bad (let $shown (println! (HostAdmissionFailed $arguments $bad)) (system:exit 1))))))
(= (ah:zero-refused $binary $arguments)
   (case (proc:run (cons-atom $binary $arguments) "." (ah:environment) 15000 1048576)
     (((proc:exited 2 "" "error: invalid fuel '0'\n") ())
      ($bad (let $shown (println! (ZeroFuelAdmissionFailed $arguments $bad)) (system:exit 1))))))
(= (ah:run $binary)
   (let* (($p1 (ah:profile $binary "petta" "extended" "ai"))
          ($p2 (ah:profile $binary "petta" "ai" "extended"))
          ($h1 (ah:check $binary he-unavailable
            ("--lang" "he" "--profile" "ai" "-e" "!(ai:experiment failure-values) !(+ 2 3)")
            "[(Error (ai:experiment failure-values) (Forbidden ExperimentUnavailableInHost))]\n"))
          ($h2 (ah:check $binary he-off
            ("--lang" "he" "--profile" "ai" "-e" "!(car-atom [1 2]) !(+ 2 3)")
            "[1]\n[5]\n"))
          ($off (ah:check $binary off
            ("--lang" "ai" "-e" "!(Box (Error first (Fault detail))) !(+ 2 3)")
            "(Box (Error first (Fault detail)))\n5\n"))
          ($on (ah:check $binary on
            ("--lang" "ai" "-e" "!(ai:experiment failure-values) !(Box (Error first (Fault detail))) !(+ 2 3)")
            "()\n(Error first (Fault detail))\n5\n"))
          ($twice (ah:check $binary idempotent
            ("--lang" "ai" "-e" "!(ai:experiment failure-values) !(ai:experiment failure-values) !(Box (Error first (Fault detail)))")
            "()\n()\n(Error first (Fault detail))\n"))
          ($unknown (ah:check $binary unknown
            ("--lang" "ai" "-e" "!(ai:experiment unknown)")
            "(Error (ai:experiment unknown) (Unsolvable UnknownExperimentOrMalformedDeclaration))\n"))
          ($malformed (ah:check $binary malformed
            ("--lang" "ai" "-e" "!(ai:experiment)")
            "(Error (ai:experiment) (Unsolvable UnknownExperimentOrMalformedDeclaration))\n"))
          ($quoted (ah:check $binary held-declaration
            ("--lang" "ai" "-e" "!(quote (ai:experiment failure-values)) !(Box (Error first (Fault detail)))")
            "(ai:experiment failure-values)\n(Box (Error first (Fault detail)))\n"))
          ($isolated (ah:check $binary stable-isolation
            ("--lang" "petta" "--profile" "extended" "-e" "!(ai:experiment failure-values) !(Box (Error first (Fault detail)))")
            "(ai:experiment failure-values)\n(Box (Error first (Fault detail)))\n"))
          ($budget (ah:check $binary zero-budget
            ("--lang" "petta" "--profile" "ai" "--fuel" "0" "-e" "!(ai:experiment failure-values) !(+ 1 2)")
            "()\n(Error (+ 1 2) (Incomplete fuel-exhausted))\n"))
          ($partial (ah:check $binary partial-budget
            ("--lang" "petta" "--profile" "ai" "--fuel" "30" "-e"
             "!(ai:experiment failure-values) (= (spin $x) (spin $x)) !(collapse (superpose (1 (spin 0))))")
            "()\n(1 (Error (superpose (1 (spin 0))) (Incomplete fuel-exhausted)))\n"))
          ($preset-off (ah:check $binary preset-off
            ("--lang" "petta" "--profile" "ai" "-e" "!(Box (Error first (Fault detail)))")
            "(Box (Error first (Fault detail)))\n"))
          ($empty-data (ah:check $binary no-space-injection
            ("--lang" "ai" "-e" "!(ai:experiment failure-values) !(collapse (match &self (: Empty $type) $type)) !(Empty scope)")
            "()\n()\n(Empty scope)\n"))
          ($bad-first (ah:reject $binary
            ("--lang" "petta" "--profile" "ai" "--profile" "typecheck-v2" "-e" "!(+ 1 2)")))
          ($bad-last (ah:reject $binary
            ("--lang" "petta" "--profile" "typecheck-v2" "--profile" "ai" "-e" "!(+ 1 2)")))
          ($bad-dialect (ah:reject $binary
            ("--lang" "ai" "--profile" "typecheck-v2" "-e" "!(+ 1 2)")))
          ($zero-version (ah:zero-refused $binary ("--fuel" "0" "--version")))
          ($zero-language (ah:zero-refused $binary ("--fuel" "0" "--lang" "nosuch" "-e" "!(x)")))
          ($zero-profile (ah:zero-refused $binary ("--fuel" "0" "--profile" "nosuch" "-e" "!(x)"))))
     (HostControlsPass 21)))
