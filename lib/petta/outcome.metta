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

; Any expression headed by Error, of any arity, is a failure: natives answer
; (Error CALL MESSAGE) and catch answers (Error TYPE CONTEXT).
(= (out:failed? $value)
   (if (== (get-metatype $value) Expression)
     (if (== $value ()) False (== (car-atom $value) Error))
     False))
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

(= (out:empty $scope) (Empty $scope))
(= (out:absent? $value)
   (case $value (((Empty $scope) True) ($other False))))

; The first failure among already computed values, in list order, or ().
(= (out:first-failure $values)
   (if (== $values ()) ()
     (let $head (car-atom $values)
       (if (out:failed? $head) $head
         (let $tail (cdr-atom $values) (out:first-failure $tail))))))

; Check computed values, then compute the held body: the first failing value
; is the result, and the body does not run.
(: out:with (-> Atom Atom %Undefined%))
(= (out:with $values $body)
   (let $failure (out:first-failure $values)
     (if (== $failure ()) (eval $body) $failure)))

; Sequential binding that stops at the first failure.  A binding whose value
; has no answers leaves no answers: zero is not a failure.
(: out:let* (-> Atom Atom %Undefined%))
(= (out:let* $bindings $body)
   (if (== $bindings ()) (eval $body)
     (let* (($binding (car-atom $bindings))
            ($pattern (car-atom $binding))
            ($source (car-atom (cdr-atom $binding)))
            ($value (eval $source)))
       (if (out:failed? $value) $value
         (let $rest (cdr-atom $bindings)
           (let $pattern $value (out:let* $rest $body)))))))
(: out:let (-> Atom Atom Atom %Undefined%))
(= (out:let $pattern $source $body)
   (let $value (eval $source)
     (if (out:failed? $value) $value (let $pattern $value (eval $body)))))

; Compute held expressions in order: their values as a list, or the first
; failure, after which nothing more is computed.
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
; value is no verdict, which is neither branch.
(: out:if (-> Atom Atom Atom %Undefined%))
(= (out:if $condition $then $else)
   (let $verdict (eval $condition)
     (if (== $verdict True) (eval $then)
       (if (== $verdict False) (eval $else)
         (out:no-verdict out:if $verdict)))))
(= (out:no-verdict $where $verdict)
   (if (out:failed? $verdict) $verdict
     (out:unsolvable $where (NoVerdict $verdict))))
(: out:and (-> Atom %Undefined%))
(= (out:and $conditions)
   (if (== $conditions ()) True
     (let* (($first (car-atom $conditions)) ($verdict (eval $first)))
       (if (== $verdict True) (let $rest (cdr-atom $conditions) (out:and $rest))
         (if (== $verdict False) False (out:no-verdict out:and $verdict))))))
(: out:or (-> Atom %Undefined%))
(= (out:or $conditions)
   (if (== $conditions ()) False
     (let* (($first (car-atom $conditions)) ($verdict (eval $first)))
       (if (== $verdict False) (let $rest (cdr-atom $conditions) (out:or $rest))
         (if (== $verdict True) True (out:no-verdict out:or $verdict))))))
; A requirement: True, or the failure it names.
(= (out:require $condition $kind $where $detail)
   (if (== $condition True) True
     (if (== $condition False) (out:fail $kind $where $detail)
       (out:no-verdict $where $condition))))

; Observing a failure.  A raised error inside the held expression is caught
; and becomes its (Error ...) value first.
(: out:recover (-> Atom Atom Atom %Undefined%))
(= (out:recover $source $failure $handler)
   (let $value (catch (eval $source))
     (if (out:failed? $value) (let $failure $value (eval $handler)) $value)))
(: out:or-else (-> Atom Atom %Undefined%))
(= (out:or-else $source $default)
   (let $value (catch (eval $source))
     (if (out:failed? $value) (eval $default) $value)))
(: out:catch (-> Atom %Undefined%))
(= (out:catch $source) (catch (eval $source)))

; Zero observed as data.  out:one requires exactly one answer; out:first
; reports a completed empty answer set as (Empty SCOPE).
(: out:one (-> Atom Atom %Undefined%))
(= (out:one $source $where)
   (let $answers (collapse (eval $source))
     (if (== $answers ()) (out:unsolvable $where no-answer)
       (if (== (size-atom $answers) 1) (car-atom $answers)
         (out:unsolvable $where (ambiguous (size-atom $answers)))))))
(: out:first (-> Atom Atom %Undefined%))
(= (out:first $source $scope)
   (let $answers (collapse (eval $source))
     (if (== $answers ()) (Empty $scope) (car-atom $answers))))
