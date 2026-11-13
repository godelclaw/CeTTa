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
   "!(let $x (Error first (Fault detail)) never) !(car-atom [1 2]) !(if (== r#\"a\\n\"# \"a\\\\n\") raw bad)")
(= (ah:profile $binary $language $first $second)
   (let* (($source (ah:profile-source))
          ($wanted (if (== $language "he")
            "[(Error first (Fault detail))]\n[1]\n[raw]\n"
            "(Error first (Fault detail))\n1\nraw\n")))
     (ah:check $binary (Profiles $language $first $second)
       ("--lang" $language "--profile" $first "--profile" $second "-e" $source) $wanted)))
(= (ah:run $binary)
   (let* (($p1 (ah:profile $binary "petta" "extended" "ai"))
          ($p2 (ah:profile $binary "petta" "ai" "extended"))
          ($h1 (ah:profile $binary "he" "extended" "ai"))
          ($h2 (ah:profile $binary "he" "ai" "extended"))
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
            ("--lang" "petta" "--profile" "ai" "--fuel" "0" "-e" "!(+ 1 2)")
            "(Error (+ 1 2) (Incomplete fuel-exhausted))\n"))
          ($partial (ah:check $binary partial-budget
            ("--lang" "petta" "--profile" "ai" "--fuel" "30" "-e"
             "(= (spin $x) (spin $x)) !(collapse (superpose (1 (spin 0))))")
            "(1 (Error (superpose (1 (spin 0))) (Incomplete fuel-exhausted)))\n")))
     (HostControlsPass 13)))
