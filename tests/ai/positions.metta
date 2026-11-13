!(ai:experiment failure-values)
; These controls reach value provenance, receiver matching, held patterns,
; strict Boolean/comparison arguments, and each host's empty-case policy.
(: ai-hold (-> Atom Atom))
(= (ai-hold $syntax) $syntax)
(= (ai-pattern) computed-pattern)

!(and False (Error demanded (Fault bad)))
!(or True (Error demanded (Fault bad)))
!(== (Error demanded (Fault bad)) 1)
!(chain (catch (Error source (Fault bad))) $v (Box $v))
!(let $v (quote (Error inert (Fault data))) (Box $v))
!(let (Other $x) (Box (Error field (Fault bad))) reached)
!(collapse (let (Other $x) (Box 1) reached))
!(case (superpose ()) ((Empty fallback) ($x data)))
!(collapse (case (superpose ()) (($x data))))
!(case () ((() unit) ($x other)))
!(case (ai-hold (ai-pattern)) (((ai-pattern) matched) ($other missed)))
!(unify (ai-pattern) computed-pattern wrongly-evaluated held)
!(case (catch (Error source (Fault bad))) (($x ordinary-data)))
!(case (catch (Error source (Fault bad))) (((Error $w $reason) inspectable) ($x missed)))
!(Box (ai-hold (Error held (Forbidden data))))
!(collapse (superpose ((Error origin (Fault (Error nested (Forbidden inert)))) 7)))
!(let $description (ai-hold (ai-pattern)) (Box $description))
; A callable-looking binding pattern is held, even if evaluating it would
; make an otherwise impossible match succeed.
!(collapse (let (ai-pattern) computed-pattern wrongly-evaluated))
; The observation index is already data; constructing a report never runs it.
!(let $scope (ai-hold (Query (ai-pattern))) (Empty $scope))
; Positive binding must not change the observation policy of its continuation.
!(let $unused anchor (collapse (superpose ((Error branch (Fault bad)) live))))
(= (ai-body-failure) (Error body (Fault bad)))
!(let $value (ai-body-failure) unreachable)
!(Box (ai-body-failure))
!(if (ai-body-failure) yes no)
; Explicit evaluation is activation; mere binding and inspection are not.
!(let $value (metta (Error inner (Fault bad)) %Undefined% &self) unreachable)
!(Box (metta (Error inner (Fault bad)) %Undefined% &self))
!(let $data (catch (Error source (Fault bad)))
   (let $value (eval $data) unreachable))
; PeTTa executes the selected source once; HE keeps its minimal-step eval.
!(eval (Box (Error selected-source (Fault bad))))
