; Experiment: the held forms of lib/petta/outcome.metta as translator rules.
; Same results as the library; CeTTa expands the rules at each call, so today
; they cost more than the run-time forms (see the error-system report).
; Failures, absence and answers, kept apart.
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
; The forms that take held arguments (out:let*, out:let, out:with, out:all,
; out:if, out:and, out:or, out:recover, out:or-else, out:one, out:first)
; evaluate them left to right and stop at the first failure: the earliest
; failure wins, nothing after it runs, and other branches of a
; nondeterministic computation are not touched.  The value-taking forms
; (out:cons, out:append, out:snoc, out:finish) never splice a failure into a
; list: a failure on either side is the result.

(= (out:fail $kind $where $detail) (Error $where ($kind $detail)))
(= (out:unsolvable $where $detail) (Error $where (Unsolvable $detail)))
(= (out:forbidden $where $detail) (Error $where (Forbidden $detail)))
(= (out:incomplete $where $detail) (Error $where (Incomplete $detail)))
(= (out:fault $where $detail) (Error $where (Fault $detail)))

; An expression headed by Error with one to three arguments is a failure:
; natives answer (Error CALL MESSAGE), catch answers (Error TYPE CONTEXT) or
; (Error EXCEPTION).
(= (out:failed? $value)
   (case $value
     (((Error $where $reason) True) ((Error $fault) True) ((Error $type $context $more) True)
      ($other False))))
(= (out:ok? $value) (not (out:failed? $value)))

(= (out:kind $value)
   (if (out:failed? $value)
     (case $value
       (((Error $where (Unsolvable $detail)) Unsolvable)
        ((Error $where (Forbidden $detail)) Forbidden)
        ((Error $where (Incomplete $detail)) Incomplete)
        ($other Fault)))
     Ok))
(= (out:where $value)
   (case $value (((Error $where $reason) $where) ($other ()))))
(= (out:detail $value)
   (case $value
     (((Error $where (Unsolvable $detail)) $detail)
      ((Error $where (Forbidden $detail)) $detail)
      ((Error $where (Incomplete $detail)) $detail)
      ((Error $where (Fault $detail)) $detail)
      ((Error $where $reason) $reason)
      ($other ()))))
; The same failure, reported at an outer boundary; its kind and detail stay.
(= (out:at $where $value)
   (if (out:failed? $value)
     (out:fail (out:kind $value) $where (out:detail $value))
     $value))

; A failure reified as inert data, and reflected back.  (Failed WHERE KIND
; DETAIL) is no failure: it can be compared, stored and passed in any dialect.
(: out:reify (-> Atom Atom))
(= (out:reify $source) (quote (out:reified (catch $source))))
!(add-translator-rule! out:reify)
(= (out:reified $value)
   (if (out:failed? $value)
     (Failed (out:where $value) (out:kind $value) (out:detail $value))
     $value))
(= (out:reflect $value)
   (case $value
     (((Failed $where $kind $detail) (out:fail $kind $where $detail))
      ($other $other))))

(= (out:empty $scope) (Empty $scope))
(= (out:absent? $value)
   (case $value (((Empty $scope) True) ($other False))))

; The first failure among already computed values, in list order, or ().
(= (out:first-failure $values)
   (if (== $values ()) ()
     (let $head (car-atom $values)
       (if (out:failed? $head) $head
         (let $tail (cdr-atom $values) (out:first-failure $tail))))))

; The held forms below are translator rules: each use expands, when the
; program is translated, into the let and case a person would write by hand,
; so they cost what those cost.  The names $out:... are the expansion's own.

; Check computed values, then compute the body: the first failing value is
; the result, and the body does not run.  Name values with variables; each
; is read once.
(: out:with (-> Atom Atom Atom))
(= (out:with $values $body)
   (if (== $values ()) (quote $body)
     (let* (($value (car-atom $values)) ($rest (cdr-atom $values)))
       (quote (let $out:v $value
                (case $out:v
                  (((Error $out:w $out:r) $out:v) ((Error $out:e) $out:v)
                   ((Error $out:a $out:b $out:c) $out:v)
                   ($out:ok (out:with $rest $body)))))))))
!(add-translator-rule! out:with)

; Sequential binding that stops at the first failure.  A pattern that does
; not match its value is a failure (no-match VALUE), never a silent zero, so a
; name bound twice to different values is reported.  A binding whose value has
; no answers leaves no answers: zero is not a failure.
(: out:let* (-> Atom Atom Atom))
(= (out:let* $bindings $body)
   (if (== $bindings ()) (quote $body)
     (let* (($binding (car-atom $bindings)) ($rest (cdr-atom $bindings))
            ($pattern (car-atom $binding)) ($source (car-atom (cdr-atom $binding))))
       (quote (let $out:v $source
                (case $out:v
                  (((Error $out:w $out:r) $out:v) ((Error $out:e) $out:v)
                   ((Error $out:a $out:b $out:c) $out:v)
                   ($pattern (out:let* $rest $body))
                   ($out:o (out:unsolvable out:let* (no-match $out:o))))))))))
!(add-translator-rule! out:let*)
(: out:let (-> Atom Atom Atom Atom))
(= (out:let $pattern $source $body) (quote (out:let* (($pattern $source)) $body)))
!(add-translator-rule! out:let)

; Compute expressions in order: their values as a list, or the first failure,
; after which nothing more is computed.  This one is a function over held
; expressions, evaluated at run time.
(: out:all (-> Atom %Undefined%))
(= (out:all $sources) (out:all-onto $sources ()))
(: out:all-onto (-> Atom Atom %Undefined%))
(= (out:all-onto $sources $done)
   (if (== $sources ()) (out:finish $done)
     (let* (($source (car-atom $sources)) ($value (eval $source)))
       (if (out:failed? $value) $value
         (let* (($rest (cdr-atom $sources)) ($more (cons-atom $value $done)))
           (out:all-onto $rest $more))))))

; Lists that cannot carry a failure as elements.  An earlier part's failure
; wins: the head before the tail, the left list before the right.
(= (out:cons $head $tail)
   (if (out:failed? $head) $head
     (if (out:failed? $tail) $tail (cons-atom $head $tail))))
(= (out:append $left $right)
   (if (out:failed? $left) $left
     (if (out:failed? $right) $right (out:append-onto (reverse $left) $right))))
(= (out:append-onto $reversed $tail)
   (if (== $reversed ()) $tail
     (let* (($head (car-atom $reversed)) ($rest (cdr-atom $reversed))
            ($next (cons-atom $head $tail)))
       (out:append-onto $rest $next))))
; In-order accumulation: snoc onto a newest-first list, finish once.
(= (out:snoc $newest-first $item)
   (if (out:failed? $newest-first) $newest-first
     (if (out:failed? $item) $item (cons-atom $item $newest-first))))
(= (out:finish $newest-first)
   (if (out:failed? $newest-first) $newest-first (reverse $newest-first)))

; Conditions decide only on True or False.  A failure propagates; any other
; value is no verdict, which is neither branch: an Incomplete failure, since no
; verdict is unresolved work, never a refutation.
(: out:if (-> Atom Atom Atom Atom))
(= (out:if $condition $then $else)
   (quote (let $out:c $condition
            (case $out:c
              ((True $then) (False $else)
               ((Error $out:w $out:r) $out:c) ((Error $out:e) $out:c)
               ((Error $out:a $out:b $out:d) $out:c)
               ($out:o (out:incomplete out:if (NoVerdict $out:o))))))))
!(add-translator-rule! out:if)
(= (out:no-verdict $where $verdict)
   (if (out:failed? $verdict) $verdict
     (out:incomplete $where (NoVerdict $verdict))))
(: out:and (-> Atom Atom))
(= (out:and $conditions)
   (if (== $conditions ()) (quote True)
     (let* (($first (car-atom $conditions)) ($rest (cdr-atom $conditions)))
       (quote (out:if $first (out:and $rest) False)))))
!(add-translator-rule! out:and)
(: out:or (-> Atom Atom))
(= (out:or $conditions)
   (if (== $conditions ()) (quote False)
     (let* (($first (car-atom $conditions)) ($rest (cdr-atom $conditions)))
       (quote (out:if $first True (out:or $rest))))))
!(add-translator-rule! out:or)
; A requirement: True, or the failure it names.
(= (out:require $condition $kind $where $detail)
   (if (== $condition True) True
     (if (== $condition False) (out:fail $kind $where $detail)
       (out:no-verdict $where $condition))))

; Observing a failure.  A raised error inside the held expression is caught
; and becomes its (Error ...) value first.
(: out:recover (-> Atom Atom Atom Atom))
(= (out:recover $source $failure $handler)
   (quote (let $out:v (catch $source)
            (case $out:v
              (((Error $out:w $out:r) (let $failure $out:v $handler))
               ((Error $out:e) (let $failure $out:v $handler))
               ((Error $out:a $out:b $out:c) (let $failure $out:v $handler))
               ($out:ok $out:ok))))))
!(add-translator-rule! out:recover)
(: out:or-else (-> Atom Atom Atom))
(= (out:or-else $source $default)
   (quote (out:recover $source $out:f $default)))
!(add-translator-rule! out:or-else)
(: out:catch (-> Atom Atom))
(= (out:catch $source) (quote (catch $source)))
!(add-translator-rule! out:catch)

; Zero observed as data.  out:one requires exactly one answer; out:first
; reports a completed empty answer set as (Empty SCOPE).
(: out:one (-> Atom Atom Atom))
(= (out:one $source $where) (quote (out:one-of (collapse $source) $where)))
!(add-translator-rule! out:one)
(= (out:one-of $answers $where)
   (if (== $answers ()) (out:unsolvable $where no-answer)
     (if (== (size-atom $answers) 1) (car-atom $answers)
       (out:unsolvable $where (ambiguous (size-atom $answers))))))
(: out:first (-> Atom Atom Atom))
(= (out:first $source $scope) (quote (out:first-of (collapse $source) $scope)))
!(add-translator-rule! out:first)
(= (out:first-of $answers $scope)
   (if (== $answers ()) (Empty $scope) (car-atom $answers)))
