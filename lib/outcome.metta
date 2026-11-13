; Failures, absence and answers, kept apart.  The PeTTa spelling of this
; library is lib/petta/outcome.metta; the two keep one interface.
;
; A failure is one answer, an ordinary value: (Error WHERE REASON).  A
; classified reason is (KIND DETAIL), with KIND one of
;   Unsolvable  the request has no solution: malformed input, a wrong type,
;               a missing required part.  The same request cannot succeed.
;   Forbidden   the request is well formed and a policy refuses it.  Another
;               permission may admit it, and the refused request still exists.
;   Incomplete  a budget or limit stopped the work.  It is neither absence nor
;               a refutation, and nothing here turns it into either.
;   Fault       the machinery failed (I/O, host, native), or the reason is not
;               classified.  Every legacy (Error ...) reads as a Fault.
;
; Completed absence is data, not failure: (Empty SCOPE) reports that a
; completed search at SCOPE found nothing.  No answers at all is zero, which
; only the collapse family observes: out:one and out:first report it as data.
;
; HE already ends a computation at an Error that an argument, let or let*
; produces; out:let* and out:let are that rule, written in the shared names.
; HE keeps an Error that arrives already computed (a bound value) as data, and
; when some answers of one computation are values and some are Errors, the
; Errors are not reported.  The value-taking list forms below never splice a
; failure, whichever way it arrives.

(: out:fail (-> Atom Atom %Undefined% Atom))
(= (out:fail $kind $where $detail) (Error $where ($kind $detail)))
(: out:unsolvable (-> Atom %Undefined% Atom))
(= (out:unsolvable $where $detail) (Error $where (Unsolvable $detail)))
(: out:forbidden (-> Atom %Undefined% Atom))
(= (out:forbidden $where $detail) (Error $where (Forbidden $detail)))
(: out:incomplete (-> Atom %Undefined% Atom))
(= (out:incomplete $where $detail) (Error $where (Incomplete $detail)))
(: out:fault (-> Atom %Undefined% Atom))
(= (out:fault $where $detail) (Error $where (Fault $detail)))

; The shape test, on an atom as given.  The observers below compute their
; argument first, in the caller's space: a failure is seen whether it arrives
; bound or is produced by the argument itself.
(: out:is-failure (-> Atom Bool))
(= (out:is-failure $value)
   (if (== (get-metatype $value) Expression)
     (if (== $value ()) False (== (car-atom $value) Error))
     False))
(: out:failed? (-> Atom %Undefined%))
(= (out:failed? $source)
   (chain (metta $source %Undefined% (context-space)) $value (out:is-failure $value)))
(: out:ok? (-> Atom %Undefined%))
(= (out:ok? $source)
   (chain (metta $source %Undefined% (context-space)) $value (not (out:is-failure $value))))
(: out:kind (-> Atom %Undefined%))
(= (out:kind $source)
   (chain (metta $source %Undefined% (context-space)) $value (out:kind-of $value)))
(: out:kind-of (-> Atom %Undefined%))
(= (out:kind-of $value)
   (if (out:is-failure $value)
     (case $value
       (((Error $where (Unsolvable $detail)) Unsolvable)
        ((Error $where (Forbidden $detail)) Forbidden)
        ((Error $where (Incomplete $detail)) Incomplete)
        ($other Fault)))
     Ok))
(: out:where (-> Atom %Undefined%))
(= (out:where $source)
   (chain (metta $source %Undefined% (context-space)) $value
     (case $value (((Error $where $reason) $where) ($other ())))))
(: out:detail (-> Atom %Undefined%))
(= (out:detail $source)
   (chain (metta $source %Undefined% (context-space)) $value (out:detail-of $value)))
(: out:detail-of (-> Atom %Undefined%))
(= (out:detail-of $value)
   (case $value
     (((Error $where (Unsolvable $detail)) $detail)
      ((Error $where (Forbidden $detail)) $detail)
      ((Error $where (Incomplete $detail)) $detail)
      ((Error $where (Fault $detail)) $detail)
      ((Error $where $reason) $reason)
      ($other ()))))
(: out:at (-> Atom Atom %Undefined%))
(= (out:at $where $source)
   (chain (metta $source %Undefined% (context-space)) $value
     (if (out:is-failure $value)
       (chain (metta (out:kind-of $value) %Undefined% (context-space)) $kind
         (chain (metta (out:detail-of $value) %Undefined% (context-space)) $detail
           (Error $where ($kind $detail))))
       $value)))

; HE reads an undeclared (Empty x) as no result; the constructor declaration
; keeps it data, as the scoped observations of an application declare it.
(: Empty (-> Atom ScopedObservation))
(: out:empty (-> %Undefined% %Undefined%))
(= (out:empty $scope) (Empty $scope))
(: out:absent? (-> %Undefined% %Undefined%))
(= (out:absent? $value)
   (case $value (((Empty $scope) True) ($other False))))

(: out:first-failure (-> %Undefined% %Undefined%))
(= (out:first-failure $values)
   (if-equal $values () ()
     (if (out:is-failure (car-atom $values)) (car-atom $values)
       (out:first-failure (cdr-atom $values)))))

(: out:with (-> Atom Atom %Undefined%))
(= (out:with $values $body)
   (chain (eval (out:first-failure $values)) $failure
     (if (== $failure ()) (metta $body %Undefined% (context-space)) $failure)))

; Each binding is spliced into one case that runs in the caller's space, so
; the caller's variables are the ones bound.  A pattern that does not match its
; value is a failure (no-match VALUE), never a silent zero.
(: out:let* (-> Atom Atom %Undefined%))
(= (out:let* $bindings $body)
   (if-equal $bindings () (metta $body %Undefined% (context-space))
     (chain (eval (car-atom $bindings)) $binding
       (chain (eval (cdr-atom $bindings)) $rest
         (unify $binding ($pattern $source)
           (metta (out:bind $source $pattern (out:let* $rest $body) out:let*)
                  %Undefined% (context-space))
           (Error out:let* (Unsolvable (malformed-binding $binding))))))))
(: out:let (-> Atom Atom Atom %Undefined%))
(= (out:let $pattern $source $body)
   (metta (out:bind $source $pattern $body out:let) %Undefined% (context-space)))
(: out:bind (-> Atom Atom Atom Atom %Undefined%))
(= (out:bind $source $pattern $body $where)
   (chain (metta $source %Undefined% (context-space)) $value
     (if (out:is-failure $value) $value
       (metta (case $value (($pattern $body) ($out-other (Error $where (Unsolvable (no-match $out-other))))))
              %Undefined% (context-space)))))

(: out:all (-> Atom %Undefined%))
(= (out:all $sources) (out:all-onto $sources ()))
(: out:all-onto (-> Atom Atom %Undefined%))
(= (out:all-onto $sources $done)
   (if-equal $sources () (out:finish $done)
     (chain (eval (car-atom $sources)) $first
     (chain (metta $first %Undefined% (context-space)) $value
       (if (out:is-failure $value) $value
         (chain (eval (cdr-atom $sources)) $rest
           (out:all-onto $rest (cons-atom $value $done))))))))

(: out:cons (-> %Undefined% %Undefined% %Undefined%))
(= (out:cons $head $tail)
   (if (out:is-failure $head) $head
     (if (out:is-failure $tail) $tail (cons-atom $head $tail))))
(: out:append (-> %Undefined% %Undefined% %Undefined%))
(= (out:append $left $right)
   (if (out:is-failure $left) $left
     (if (out:is-failure $right) $right (out:append-onto (out:reverse $left ()) $right))))
(: out:reverse (-> %Undefined% %Undefined% %Undefined%))
(= (out:reverse $items $done)
   (if (== $items ()) $done
     (out:reverse (cdr-atom $items) (cons-atom (car-atom $items) $done))))
(: out:append-onto (-> %Undefined% %Undefined% %Undefined%))
(= (out:append-onto $reversed $tail)
   (if (== $reversed ()) $tail
     (out:append-onto (cdr-atom $reversed) (cons-atom (car-atom $reversed) $tail))))
(: out:snoc (-> %Undefined% %Undefined% %Undefined%))
(= (out:snoc $newest-first $item)
   (if (out:is-failure $newest-first) $newest-first
     (if (out:is-failure $item) $item (cons-atom $item $newest-first))))
(: out:finish (-> %Undefined% %Undefined%))
(= (out:finish $newest-first)
   (if (out:is-failure $newest-first) $newest-first (out:reverse $newest-first ())))

(: out:if (-> Atom Atom Atom %Undefined%))
(= (out:if $condition $then $else)
   (chain (metta $condition %Undefined% (context-space)) $verdict
     (if (out:is-failure $verdict) $verdict
       (if (== $verdict True) (metta $then %Undefined% (context-space))
         (if (== $verdict False) (metta $else %Undefined% (context-space))
           (out:no-verdict out:if $verdict))))))
(: out:no-verdict (-> %Undefined% %Undefined% %Undefined%))
(= (out:no-verdict $where $verdict)
   (if (out:is-failure $verdict) $verdict
     (Error $where (Unsolvable (NoVerdict $verdict)))))
(: out:and (-> Atom %Undefined%))
(= (out:and $conditions)
   (if-equal $conditions () True
     (chain (eval (car-atom $conditions)) $first
       (chain (metta $first %Undefined% (context-space)) $verdict
       (if (out:is-failure $verdict) $verdict
         (if (== $verdict True) (chain (eval (cdr-atom $conditions)) $rest (out:and $rest))
           (if (== $verdict False) False (out:no-verdict out:and $verdict))))))))
(: out:or (-> Atom %Undefined%))
(= (out:or $conditions)
   (if-equal $conditions () False
     (chain (eval (car-atom $conditions)) $first
       (chain (metta $first %Undefined% (context-space)) $verdict
       (if (out:is-failure $verdict) $verdict
         (if (== $verdict False) (chain (eval (cdr-atom $conditions)) $rest (out:or $rest))
           (if (== $verdict True) True (out:no-verdict out:or $verdict))))))))
(= (out:require $condition $kind $where $detail)
   (if (out:is-failure $condition) $condition
   (if (== $condition True) True
     (if (== $condition False) (Error $where ($kind $detail))
       (out:no-verdict $where $condition)))))

; HE raises nothing a program can catch: natives answer Error values.
(: out:recover (-> Atom Atom Atom %Undefined%))
(= (out:recover $source $failure $handler)
   (chain (metta $source %Undefined% (context-space)) $value
     (if (out:is-failure $value)
       (metta (let $failure $value $handler) %Undefined% (context-space))
       $value)))
(: out:or-else (-> Atom Atom %Undefined%))
(= (out:or-else $source $default)
   (chain (metta $source %Undefined% (context-space)) $value
     (if (out:is-failure $value) (metta $default %Undefined% (context-space)) $value)))
(: out:catch (-> Atom %Undefined%))
(= (out:catch $source) (chain (metta $source %Undefined% (context-space)) $value $value))

(: out:one (-> Atom Atom %Undefined%))
(= (out:one $source $where)
   (chain (collapse (metta $source %Undefined% (context-space))) $answers
     (if (== $answers ()) (Error $where (Unsolvable no-answer))
       (chain (eval (size-atom $answers)) $count
         (if (== $count 1) (car-atom $answers)
           (Error $where (Unsolvable (ambiguous $count))))))))
(: out:first (-> Atom Atom %Undefined%))
(= (out:first $source $scope)
   (chain (collapse (metta $source %Undefined% (context-space))) $answers
     (if (== $answers ()) (Empty $scope) (car-atom $answers))))
