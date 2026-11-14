; Substituting a variable preserves a diagnostic's admitted data role.
; A shared template is a graph, not its exponentially unfolded tree.
!(import! &self "./he_contract.metta")

(SC chain "(let $e (catch (Error $x (Fault b))) (let $r (chain 5 $x $e) (Box $r)))" "(Box (Error 5 (Fault b)))")
(SC unrelated "(let $e (catch (Error $w (Fault b))) (let $r (chain 5 $x $e) (Box $r)))" "(Box (Error $w (Fault b)))")
(SC substitute "(let $e (catch (Error $x (Fault b))) (let $r (atom-subst 5 $x $e) (Box $r)))" "(Box (Error 5 (Fault b)))")
; These templates cross explicit eval in the standard library. Substitution
; preserves the datum first; the later code-reading boundary raises it.
(SC map "(let $e (catch (Error $x (Fault b))) (let ($r) (map-atom (5) $x $e) (Box $r)))" "(Error 5 (Fault b))")
(SC filter "(let $e (catch (Error $x (Fault b))) (filter-atom (5) $x (== $e $e)))" "(5)")
(SC fold "(let $e (catch (Error $x (Fault b))) (let $r (foldl-atom (5) 0 $acc $x $e) (Box $r)))" "(Error 5 (Fault b))")

(= (sc:check $binary $route (SubstitutionCase $name $source $wanted))
   (let* (($program (str:join "" ("!(ai:experiment failure-values) !" $source)))
          ($expected (str:join "" ("[()]\n[" $wanted "]\n"))))
     (case (proc:run ("/usr/bin/env" $route $binary "--lang" "he" "--profile" "ai" "-e" $program)
                     "." inherit 10000 1048576)
       (((proc:exited 0 $actual "")
          (if (== $actual $expected) 0
            (let $shown (println! (SubstitutionMismatch $route $name $expected $actual)) 1)))
        ($bad (let $shown (println! (SubstitutionExecutionFailed $route $name $bad)) 1))))))
(= (sc:walk $binary $route $cases $index $bad)
   (if (== $index (size-atom $cases)) (SubstitutionResults $route $index $bad)
     (let $failure (sc:check $binary $route (index-atom $cases $index))
       (sc:walk $binary $route $cases (+ $index 1) (+ $bad $failure)))))
(= (sc:run $binary $route)
   (let $cases (collapse (match &self (SC $name $source $wanted)
                              (SubstitutionCase $name $source $wanted)))
     (sc:walk $binary $route $cases 0 0)))
(= (sc:graph $binary $route)
   (let $program "!(ai:experiment failure-values) (= (dag $n $leaf) (if (== $n 0) $leaf (let $t (dag (- $n 1) $leaf) (pair $t $t)))) !(let $leaf (catch (Error $x (Fault b))) (let $d (dag 60 $leaf) (let $r (chain 5 $x $d) ok)))"
     (case (proc:run ("/usr/bin/env" $route $binary "--lang" "he" "--profile" "ai" "-e" $program)
                     "." inherit 10000 1048576)
       (((proc:exited 0 "[()]\n[ok]\n" "") (SubstitutionGraphPass $route 60))
        ($bad (SubstitutionGraphFailed $route $bad))))))
