; Explicit outcome boundaries. An event is an owned native value, not an
; Error-shaped term. Capturing an expression does not change its evaluator.
; Propagation and observation are library operations on the event channel.

(: __cetta_lib_outcome_capture (-> Atom %Undefined%))
(: __cetta_lib_outcome_capture (-> Atom Number %Undefined%))
(: __cetta_lib_outcome_value (-> Atom %Undefined%))
(: __cetta_lib_outcome_raised (-> Atom %Undefined%))
(: __cetta_lib_outcome_incomplete (-> Atom %Undefined%))
(: __cetta_lib_outcome_rechannel (-> %Undefined% Atom %Undefined%))
(: __cetta_lib_outcome_invoke (-> Atom %Undefined% %Undefined%))

(: outcome:capture (-> Atom %Undefined%))
(= (outcome:capture $source) (__cetta_lib_outcome_capture $source))
(: outcome:budget (-> Atom Number %Undefined%))
(= (outcome:budget $source $budget) (__cetta_lib_outcome_capture $source $budget))
(: outcome:value (-> Atom %Undefined%))
(= (outcome:value $value) (__cetta_lib_outcome_value $value))
(: outcome:raise (-> Atom %Undefined%))
(= (outcome:raise $diagnostic) (__cetta_lib_outcome_raised $diagnostic))
(: outcome:incomplete (-> Atom %Undefined%))
(= (outcome:incomplete $diagnostic) (__cetta_lib_outcome_incomplete $diagnostic))
(= (outcome:kind $event) (__cetta_lib_outcome_kind $event))
(= (outcome:payload $event) (__cetta_lib_outcome_payload $event))
(= (outcome:observe $event) (outcome-internal:report-event $event))
(= (outcome:equal $left $right) (__cetta_lib_outcome_equal $left $right))
(= (outcome:pack $events) (__cetta_lib_outcome_pack $events))
(: outcome:invoke (-> Atom %Undefined% %Undefined%))
(= (outcome:invoke $head $arguments) (__cetta_lib_outcome_invoke $head $arguments))

; A continuation receives only the value channel. Diagnostic-shaped data
; is bound by chain rather than submitted again as fresh evaluator source.
(: outcome:bind (-> Atom Atom Atom %Undefined%))
(= (outcome-internal:propagate $event)
   (if (== (outcome:kind $event) data)
     (outcome:raise (Error outcome:bind (Unsolvable ExpectedOutcomeEvent))) $event))
(= (outcome:bind $source $binder $body)
   (chain (metta $source %Undefined% (context-space)) $outcome:event
     (if (== (outcome:kind $outcome:event) value)
       (chain (eval (__cetta_lib_outcome_payload $outcome:event)) $binder
         (metta $body %Undefined% (context-space)))
       (outcome-internal:propagate $outcome:event))))
(: outcome:catch (-> Atom %Undefined%))
(= (outcome:catch $source)
   (chain (metta $source %Undefined% (context-space)) $outcome:event (outcome:observe $outcome:event)))
; The channel retains the native diagnostic exactly. This explicit report
; adapter supplies the shared Error vocabulary without classifying data as
; control. Descriptions in WHERE and DETAIL remain held syntax.
(: outcome-internal:report-event (-> %Undefined% %Undefined%))
(= (outcome-internal:report-event $event)
   (if (== (outcome:kind $event) raised)
     (chain (eval (__cetta_lib_outcome_payload $event)) $diagnostic
       (case $diagnostic
         (((Error $where (Unsolvable $detail)) (__cetta_lib_outcome_rechannel $event value))
          ((Error $where (Forbidden $detail)) (__cetta_lib_outcome_rechannel $event value))
          ((Error $where (Incomplete $detail)) (__cetta_lib_outcome_rechannel $event value))
          ((Error $where (Fault $detail)) (__cetta_lib_outcome_rechannel $event value))
          ((Error $where $reason) (outcome:value (Error $where (Fault $reason))))
          ($other (outcome:value (Error evaluation (Fault $other)))))))
     (__cetta_lib_outcome_rechannel $event value)))
(: outcome:report (-> Atom %Undefined%))
(= (outcome:report $source) (outcome:catch $source))
(= (outcome:failure-kind $event)
   (if (== (outcome:kind $event) incomplete) Incomplete
     (if (== (outcome:kind $event) raised)
       (chain (eval (__cetta_lib_outcome_payload $event)) $diagnostic
         (unify $diagnostic (Error $where (Unsolvable $detail)) Unsolvable
           (unify $diagnostic (Error $where (Forbidden $detail)) Forbidden
             (unify $diagnostic (Error $where (Incomplete $detail)) Incomplete Fault))))
       NotFailure)))
(: outcome:if (-> Atom Atom Atom %Undefined%))
(= (outcome:if $condition $yes $no)
   (outcome:bind $condition $outcome:condition
     (if (== $outcome:condition True) $yes
       (if (== $outcome:condition False) $no
         (outcome:incomplete (Error if (Incomplete (NoVerdict $outcome:condition))))))))
(: outcome:choice (-> Atom %Undefined%))
(= (outcome:choice $branches)
   (chain (eval (superpose $branches)) $outcome:branch
     (metta $outcome:branch %Undefined% (context-space))))

; Observation turns every channel into data before collecting or applying
; a set operation. A repeated failure is an occurrence until that operation
; explicitly deduplicates it, just as a repeated ordinary value is.
(: outcome:collapse (-> Atom %Undefined%))
(= (outcome:collapse $source)
   (let $outcome:events (collapse (metta $source %Undefined% (context-space)))
     (outcome:pack (map-atom $outcome:events $outcome:item (outcome:observe $outcome:item)))))
(= (outcome-internal:member $event $events)
   (if (== $events ()) False
     (if (outcome:equal $event (car-atom $events)) True
       (outcome-internal:member $event (cdr-atom $events)))))
(= (outcome-internal:unique $events $seen)
   (if (== $events ()) ()
     (let* (($event (car-atom $events)) ($rest (cdr-atom $events)))
       (if (outcome-internal:member $event $seen)
         (outcome-internal:unique $rest $seen)
         (let* (($next-seen (cons-atom $event $seen))
                ($tail (outcome-internal:unique $rest $next-seen)))
           (cons-atom $event $tail))))))
(: outcome:unique (-> Atom %Undefined%))
(= (outcome:unique $source)
   (let* (($outcome:events (collapse (metta $source %Undefined% (context-space))))
          ($outcome:observed (map-atom $outcome:events $outcome:item (outcome:observe $outcome:item))))
     (let $outcome:distinct (outcome-internal:unique $outcome:observed ())
       (superpose $outcome:distinct))))
(= (outcome-internal:filter $left $right $include)
   (if (== $left ()) ()
     (let* (($event (car-atom $left)) ($rest (cdr-atom $left)))
       (if (== (outcome-internal:member $event $right) $include)
         (let $tail (outcome-internal:filter $rest $right $include) (cons-atom $event $tail))
         (outcome-internal:filter $rest $right $include)))))
(: outcome:intersection (-> Atom Atom %Undefined%))
(= (outcome:intersection $left $right)
   (let* (($outcome:first (collapse (metta $left %Undefined% (context-space))))
          ($outcome:second (collapse (metta $right %Undefined% (context-space))))
          ($outcome:left (map-atom $outcome:first $outcome:item (outcome:observe $outcome:item)))
          ($outcome:right (map-atom $outcome:second $outcome:item (outcome:observe $outcome:item))))
     (let $outcome:selected (outcome-internal:filter $outcome:left $outcome:right True)
       (superpose $outcome:selected))))
(: outcome:subtraction (-> Atom Atom %Undefined%))
(= (outcome:subtraction $left $right)
   (let* (($outcome:first (collapse (metta $left %Undefined% (context-space))))
          ($outcome:second (collapse (metta $right %Undefined% (context-space))))
          ($outcome:left (map-atom $outcome:first $outcome:item (outcome:observe $outcome:item)))
          ($outcome:right (map-atom $outcome:second $outcome:item (outcome:observe $outcome:item))))
     (let $outcome:selected (outcome-internal:filter $outcome:left $outcome:right False)
       (superpose $outcome:selected))))
