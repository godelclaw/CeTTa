!(import! &self "./he_producers.metta")
!(import! &self "./host_controls.metta")

(= (hs:budgets $binary)
   (let* (($zero (ah:check $binary he-zero-budget
                    ("--lang" "he" "--profile" "ai" "--fuel" "0" "-e"
                     "!(ai:experiment failure-values) !(+ 1 2)")
                    "[()]\n[(Error (+ 1 2) (Incomplete fuel-exhausted))]\n"))
          ($partial (ah:check $binary he-partial-budget
                    ("--lang" "he" "--profile" "ai" "--fuel" "30" "-e"
                     "!(ai:experiment failure-values) (= (spin $x) (spin $x)) !(collapse (superpose (1 (spin 0)))) !(+ 3 4)")
                    "[()]\n[(1 (Error (superpose (1 (spin 0))) (Incomplete fuel-exhausted)))]\n[7]\n")))
     (HEBudgetControlsPass 2)))
(= (hs:run $binary)
   (case ((kh:run $binary "CETTA_HE_CANONICAL_EXECUTION=1")
          (kh:run $binary "CETTA_HE_CANONICAL_EXECUTION=0")
          (kh:nested $binary "CETTA_HE_CANONICAL_EXECUTION=1")
          (kh:nested $binary "CETTA_HE_CANONICAL_EXECUTION=0")
          (hp:run $binary "CETTA_HE_CANONICAL_EXECUTION=1")
          (hp:run $binary "CETTA_HE_CANONICAL_EXECUTION=0")
          (hs:budgets $binary))
     ((((HEContractResults $canonical 92 0) (HEContractResults $reference 92 0)
        (HEContractResults $canonical 900 0) (HEContractResults $reference 900 0)
        (HEProducerResults $canonical 63 0) (HEProducerResults $reference 63 0)
        (HEBudgetControlsPass 2)) (HEAISuitePass 1984 126 2))
      ($bad (let $shown (println! (HEAISuiteFailed $bad)) (system:exit 1))))))

; The graph has only linear physical size. An exponential unfolding must
; fail this bounded child run rather than consume the whole suite's budget.
(= (hs:graph $binary $route)
   (let $program "!(ai:experiment failure-values) (= (dag $n $leaf) (if (== $n 0) $leaf (let $t (dag (- $n 1) $leaf) (pair $t $t)))) !(let $d (dag 60 $x) (let $x 1 (let $e $d ok)))"
     (case (proc:run ("/usr/bin/env" $route $binary "--lang" "he" "--profile" "ai" "-e" $program)
                     "." inherit 10000 1048576)
       (((proc:exited 0 "[()]\n[ok]\n" "") (HESharedGraphPass $route 60))
        ($bad (HESharedGraphFailed $route $bad))))))

; Stored diagnostics may be shared leaves of a large value graph. This
; exercises the direct data admission without invoking a pattern search.
(= (hs:data-graph $binary $route)
   (let $program "!(ai:experiment failure-values) (= (dag $n $leaf) (if (== $n 0) $leaf (let $t (dag (- $n 1) $leaf) (pair $t $t)))) !(let $leaf (catch (Error stored (Fault b))) (let $d (dag 60 $leaf) (let $s (new-space) (let $added (add-atom $s (Item $d)) (let $read (get-atoms $s) (let $forced $read ok))))))"
     (case (proc:run ("/usr/bin/env" $route $binary "--lang" "he" "--profile" "ai" "-e" $program)
                     "." inherit 10000 1048576)
       (((proc:exited 0 "[()]\n[ok]\n" "") (HESharedDataGraphPass $route 60))
        ($bad (HESharedDataGraphFailed $route $bad))))))
