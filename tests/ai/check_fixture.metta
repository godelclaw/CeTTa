; The test driver runs in the stable extended dialect. The candidate child
; runs the experimental dialect/profile, with no Python test implementation.
!(import! &self (library proc))
!(import! &self (library fs))
!(import! &self (library system))

(= (ai-test:check $binary $language $route $fixture $expected $cwd)
   (let $wanted (fs:read-text $expected)
     (case (proc:run
              ("/usr/bin/env" $route $binary "--lang" $language "--profile" "ai" $fixture)
              $cwd inherit 60000 8388608)
       (((proc:exited 0 $actual "")
         (if (== $actual $wanted) (Pass $language $route $fixture)
           (let $shown (println! (Mismatch $language $route $fixture $wanted $actual))
             (system:exit 1))))
        ($other
         (let $shown (println! (UnexpectedExecution $other)) (system:exit 1)))))))
