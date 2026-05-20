!(register-module! ../codex)
!(import! &self list)
!(import! &self codex:tool_mentions)
!(import! &self codex:skill_mention_counts)
!(import! &self codex:skill_explicit_mentions)

(= (codex-test-skill $name $path)
   (CodexSkillMetadata
     $name
     "test"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     $path
     (CodexSkillScopeUser)
     True))

(= (codex-test-skill-names $skills)
   (if (== $skills ())
       ()
       (let $head (list:first $skills)
         (let $tail (list:rest $skills)
           (let $name (codex:skill-explicit-skill-name $head)
             (let $tail-names (codex-test-skill-names $tail)
               (cons-atom $name $tail-names)))))))

!(assertEqualToResult
  (codex-test-skill-names
    (codex:collect-explicit-skill-mentions
      ((CodexUserInputText "first $alpha-skill then $beta-skill" ()))
      ((codex-test-skill "beta-skill" "/tmp/beta")
       (codex-test-skill "alpha-skill" "/tmp/alpha"))
      ()
      ()))
  (("beta-skill" "alpha-skill")))

!(assertEqualToResult
  (codex-test-skill-names
    (codex:collect-explicit-skill-mentions
      ((CodexUserInputText "please run $alpha-skill" ())
       (CodexUserInputSkill "beta-skill" "/tmp/beta"))
      ((codex-test-skill "alpha-skill" "/tmp/alpha")
       (codex-test-skill "beta-skill" "/tmp/beta"))
      ()
      ()))
  (("beta-skill" "alpha-skill")))

!(assertEqualToResult
  (codex:collect-explicit-skill-mentions
    ((CodexUserInputText "please run $alpha-skill" ())
     (CodexUserInputSkill "alpha-skill" "/tmp/missing"))
    ((codex-test-skill "alpha-skill" "/tmp/alpha"))
    ()
    ())
  (()))

!(assertEqualToResult
  (codex:collect-explicit-skill-mentions
    ((CodexUserInputText "please run $alpha-skill" ())
     (CodexUserInputSkill "alpha-skill" "/tmp/alpha"))
    ((codex-test-skill "alpha-skill" "/tmp/alpha"))
    ("/tmp/alpha")
    ())
  (()))

!(assertEqualToResult
  (codex-test-skill-names
    (codex:collect-explicit-skill-mentions
      ((CodexUserInputText
         "use [$alpha-skill](/tmp/alpha) and [$alpha-skill](/tmp/alpha)"
         ()))
      ((codex-test-skill "alpha-skill" "/tmp/alpha"))
      ()
      ()))
  (("alpha-skill")))

!(assertEqualToResult
  (codex:collect-explicit-skill-mentions
    ((CodexUserInputText "use $demo-skill and again $demo-skill" ()))
    ((codex-test-skill "demo-skill" "/tmp/alpha")
     (codex-test-skill "demo-skill" "/tmp/beta"))
    ()
    ())
  (()))

!(assertEqualToResult
  (codex-test-skill-names
    (codex:collect-explicit-skill-mentions
      ((CodexUserInputText "use $demo-skill and [$demo-skill](/tmp/beta)" ()))
      ((codex-test-skill "demo-skill" "/tmp/alpha")
       (codex-test-skill "demo-skill" "/tmp/beta"))
      ()
      ()))
  (("demo-skill")))

!(assertEqualToResult
  (codex:skill-explicit-skill-path
    (list:first
      (codex:collect-explicit-skill-mentions
        ((CodexUserInputText "use $demo-skill and [$demo-skill](/tmp/beta)" ()))
        ((codex-test-skill "demo-skill" "/tmp/alpha")
         (codex-test-skill "demo-skill" "/tmp/beta"))
        ()
        ())))
  ("/tmp/beta"))

!(assertEqualToResult
  (codex:collect-explicit-skill-mentions
    ((CodexUserInputText "use $alpha-skill" ()))
    ((codex-test-skill "alpha-skill" "/tmp/alpha"))
    ()
    ((codex:skill-name-count "alpha-skill" 1)))
  (()))

!(assertEqualToResult
  (codex-test-skill-names
    (codex:collect-explicit-skill-mentions
      ((CodexUserInputText "use [$alpha-skill](/tmp/alpha)" ()))
      ((codex-test-skill "alpha-skill" "/tmp/alpha"))
      ()
      ((codex:skill-name-count "alpha-skill" 1))))
  (("alpha-skill")))

!(assertEqualToResult
  (codex:collect-explicit-skill-mentions
    ((CodexUserInputText "use [$demo-skill](/tmp/alpha)" ()))
    ((codex-test-skill "demo-skill" "/tmp/alpha")
     (codex-test-skill "demo-skill" "/tmp/beta"))
    ("/tmp/alpha")
    ())
  (()))

!(assertEqualToResult
  (codex:skill-explicit-skill-path
    (list:first
      (codex:collect-explicit-skill-mentions
        ((CodexUserInputText "use [$demo-skill](/tmp/beta)" ()))
        ((codex-test-skill "demo-skill" "/tmp/alpha")
         (codex-test-skill "demo-skill" "/tmp/beta"))
        ()
        ())))
  ("/tmp/beta"))

!(assertEqualToResult
  (codex:collect-explicit-skill-mentions
    ((CodexUserInputText "use [$demo-skill](/tmp/missing)" ()))
    ((codex-test-skill "demo-skill" "/tmp/alpha")
     (codex-test-skill "demo-skill" "/tmp/beta"))
    ()
    ())
  (()))

!(assertEqualToResult
  (codex:collect-explicit-skill-mentions
    ((CodexUserInputText
       "use [$calendar](app://calendar) and [$plugin](plugin://demo)"
       ()))
    ((codex-test-skill "calendar" "/tmp/calendar")
     (codex-test-skill "plugin" "/tmp/plugin"))
    ()
    ())
  (()))
