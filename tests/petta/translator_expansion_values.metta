; Where a translator rule runs decides what it reads.  Run once, where the
; code calling it is translated, a rule reads the call's variables as
; variables, as SWI-PeTTa does: the code it answers reads their values when
; it runs and never evaluates a value again, exactly as the same code written
; by hand.  Run at each call (CETTA_PETTA_TRANSLATOR_EXPANSION=0), CeTTa
; substitutes the values into the answer before running it, so a value that
; holds a call is evaluated a second time.  The two runs differ only there:
; translator_expansion_values.expected and .per-call.expected.

(= (tv:foo 1) called)
(= (tv:foo 2) called-again)
(: tv:for (-> Atom Atom Atom %Undefined%))
(= (tv:for $var $collection $body)
   (quote (let $var (superpose $collection) $body)))
!(add-translator-rule! tv:for)
(= (tv:items) (quote ((tv:foo 1) (tv:foo 2))))
(= (tv:each $items) (tv:for $x $items $x))
(= (tv:each-by-hand $items) (let $x (superpose $items) $x))
!(collapse (tv:each (tv:items)))
!(collapse (tv:each-by-hand (tv:items)))
; A value that does not hold a call reads the same either way.
!(collapse (tv:each (1 2 3)))

(: tv:hold (-> Atom %Undefined%))
(= (tv:hold $x) (quote (let $q $x $q)))
!(add-translator-rule! tv:hold)
(= (tv:held $a) (tv:hold $a))
!(tv:held (quote (tv:foo 1)))
!(tv:held 7)
