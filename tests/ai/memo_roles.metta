; AI_UNTABLED declines the atom-only cache at entry. The ordinary evaluator
; retains source/data roles on both misses and would-be cache replays.
!(import! &self "./he_contract.metta")

(= (mr:identity)
   "(: memo-hold (-> Atom %Undefined%)) (= (memo-hold $x) $x) !(memoize memo-hold) ")
(= (mr:data-call)
   "!(let $d (catch (Error origin (Forbidden reason))) (let $r (memo-hold $d) (Box $r))) ")
(= (mr:source-call)
   "!(let $r (memo-hold (Error origin (Forbidden reason))) reached) ")
(= (mr:data-answer) "(Box (Error origin (Forbidden reason)))\n")
(= (mr:source-answer) "(Error origin (Forbidden reason))\n")
(= (mr:program $body)
   (str:join "" ("!(ai:experiment failure-values) !(import! &self (library lib_memo)) "
                 (mr:identity) $body)))
(= (mr:prefix) "()\ntrue\ntrue\n")

(= (mr:cases)
   ((MemoCase data-first
      (mr:program (str:join "" ((mr:data-call) (mr:source-call) (mr:data-call) (mr:source-call))))
      (str:join "" ((mr:prefix) (mr:data-answer) (mr:source-answer) (mr:data-answer) (mr:source-answer))))
    (MemoCase source-first
      (mr:program (str:join "" ((mr:source-call) (mr:data-call) (mr:source-call) (mr:data-call))))
      (str:join "" ((mr:prefix) (mr:source-answer) (mr:data-answer) (mr:source-answer) (mr:data-answer))))
    (MemoCase semantic-mode
      "!(import! &self (library lib_memo)) (= (mode-call $x) (Error origin (Forbidden reason))) !(memoize mode-call) !(mode-call 1) !(ai:experiment failure-values) !(let $r (mode-call 1) reached)"
      "true\ntrue\n(Error origin (Forbidden reason))\n()\n(Error origin (Forbidden reason))\n")
    (MemoCase ordinary-uncached
      "!(ai:experiment failure-values) !(import! &self (library lib_memo)) (= (square $x) (* $x $x)) !(memoize square) !(square 9) !(square 9) !(get-memoize-stats)"
      "()\ntrue\ntrue\n81\n81\n()\n")
    (MemoCase inactive-hit
      "!(import! &self (library lib_memo)) (= (square $x) (* $x $x)) !(memoize square) !(square 9) !(square 9) !(get-memoize-stats)"
      "true\ntrue\n81\n81\n((cache_hit 1) (cache_miss 1))\n")
    (MemoCase independent-alternatives
      "!(ai:experiment failure-values) !(import! &self (library lib_memo)) (= (choose $x) (Error origin (Forbidden reason))) (= (choose $x) $x) !(memoize choose) !(collapse (choose live)) !(collapse (choose live))"
      "()\ntrue\ntrue\n((Error origin (Forbidden reason)) live)\n((Error origin (Forbidden reason)) live)\n")))

(= (mr:check $binary $route (MemoCase $name $source $wanted))
   (case (proc:run ("/usr/bin/env" $route $binary "--lang" "petta" "--profile" "ai" "-e" $source)
                   "." inherit 15000 1048576)
     (((proc:exited 0 $actual "")
        (if (== $actual $wanted) 0
          (let $shown (println! (MemoRoleMismatch $route $name $wanted $actual)) 1)))
      ($bad (let $shown (println! (MemoRoleExecutionFailed $route $name $bad)) 1)))))
(= (mr:walk $binary $route $cases $index $bad)
   (if (== $index (size-atom $cases)) (MemoRoleResults $route $index $bad)
     (let $failure (mr:check $binary $route (index-atom $cases $index))
       (mr:walk $binary $route $cases (+ $index 1) (+ $bad $failure)))))
(= (mr:run $binary $route) (mr:walk $binary $route (mr:cases) 0 0))
