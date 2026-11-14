; A finished projection retains its children's origins. Matching a container
; does not execute discarded source; returning that source root does.
!(import! &self "./activation.metta")

(= (pr:prefix) "(: phold (-> Atom Atom)) (= (phold $x) $x) ")
(= (pr:mixed $body)
   (str:join "" ("(let $d (catch (Error value (Fault datum))) "
     "(let $box (phold (Box (Error value (Fault datum)) $d)) "
     "(let $outer (cons-atom $box ()) " $body ")))")))

(Projection all new-diagnostic-root "" "(let $v (cons-atom Error (value (Fault datum))) (Box $v))" "(Box (Error value (Fault datum)))")
(Projection all constructed-source-child "" "(let $box (cons-atom Box ((Error value (Fault datum)))) (let (Box $e) $box $e))" "(Error value (Fault datum))")
(Projection all constructed-data-child "" "(let $d (catch (Error value (Fault datum))) (let $box (cons-atom Box ($d)) (let (Box $e) $box (Box $e))))" "(Box (Error value (Fault datum)))")
(Projection all mixed-let-discard (pr:prefix) (pr:mixed "(let (Box $s $d) (index-atom $outer 0) reached)") "reached")
(Projection all mixed-let-source (pr:prefix) (pr:mixed "(let (Box $s $d) (index-atom $outer 0) $s)") "(Error value (Fault datum))")
(Projection all mixed-let-data (pr:prefix) (pr:mixed "(let (Box $s $d) (index-atom $outer 0) (Box $d))") "(Box (Error value (Fault datum)))")
(Projection all mixed-case-source (pr:prefix) (pr:mixed "(case (index-atom $outer 0) (((Box $s $d) $s)))") "(Error value (Fault datum))")
(Projection all mixed-case-data (pr:prefix) (pr:mixed "(case (index-atom $outer 0) (((Box $s $d) (Box $d))))") "(Box (Error value (Fault datum)))")
(Projection he decons-discards-source "" "(let ($h $t) (decons-atom ((Error value (Fault datum)) 7)) reached)" "reached")
(Projection he decons-preserves-source "" "(let ($h $t) (decons-atom ((Error value (Fault datum)) 7)) $h)" "(Error value (Fault datum))")
(Projection he decons-preserves-data "" "(let $d (catch (Error value (Fault datum))) (let ($h $t) (decons-atom ($d 7)) (Box $h)))" "(Box (Error value (Fault datum)))")

(= (pr:walk $binary $language $route $cases $index $bad)
   (if (== $index (size-atom $cases)) (ProjectionRoleResults $language $route $index $bad)
     (let* (((ProjectionCase $name $prefix $source $wanted) (index-atom $cases $index))
            ($declarations (eval $prefix)) ($code (eval $source))
            ($failure (act:check-source $binary $language $route $name $declarations $code $wanted)))
       (pr:walk $binary $language $route $cases (+ $index 1) (+ $bad $failure)))))
(= (pr:run $binary $language $route)
   (let $cases (collapse
          (let (Entry $scope $name $prefix $source $wanted)
               (match &self (Projection $scope $name $prefix $source $wanted)
                    (Entry $scope $name $prefix $source $wanted))
            (if (or (== $scope all) (== (repr $scope) $language))
                (ProjectionCase $name $prefix $source $wanted) (superpose ()))))
     (pr:walk $binary $language $route $cases 0 0)))
