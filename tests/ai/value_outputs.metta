; Returns preserve occurrence origin. Written failures raise; caught, stored
; and freshly constructed diagnostic data stay data through the same carriers.
!(import! &self "./he_contract.metta")

(VOProducer "all" explicit-return "" "(function (return (Error value (Fault datum))))" source)
(VOProducer "all" atom-result "(: vhold (-> Atom Atom)) (= (vhold $x) $x) " "(vhold (Error value (Fault datum)))" source)
; HE holds Expression inputs; PeTTa evaluates them, so its corresponding
; value-output control obtains an admitted datum first.
(VOProducer "he" expression-result "(: vhold (-> Expression Expression)) (= (vhold $x) $x) " "(vhold (Error value (Fault datum)))" source)
(VOProducer "petta" expression-admitted-result "(: vhold (-> Expression Expression)) (= (vhold $x) $x) " "(vhold (catch (Error value (Fault datum))))" data)
(VOProducer "all" several-arguments "(: vhold (-> Atom Atom Atom)) (= (vhold $a $b) $b) " "(vhold ignored (Error value (Fault datum)))" source)
(VOProducer "all" delimited-result "(: vhold (-> Atom Atom)) (= (vhold $x) (function (return $x))) " "(vhold (Error value (Fault datum)))" source)
(VOProducer "all" authored-atom-result "(: vhold (-> Atom)) (= (vhold) (Error value (Fault datum))) " "(vhold)" source)
(VOProducer "all" typed-metta "" "(metta (Error value (Fault datum)) Atom &self)" source)
; This is an HE stdlib operation, not an implicit PeTTa import.
(VOProducer "he" substitution-result "" "(atom-subst value $x (Error $x (Fault datum)))" source)
(VOProducer "all" native-source "" "(index-atom ((Error value (Fault datum))) 0)" source)
(VOProducer "all" caught-data "" "(catch (Error value (Fault datum)))" data)
(VOProducer "all" constructed-data "" "(cons-atom Error (value (Fault datum)))" data)
(VOProducer "all" stored-data "(VRow (Error value (Fault datum))) " "(match &self (VRow $x) $x)" data)

(VOProducer "all" admitted-return "" "(let $d (catch (Error value (Fault datum))) (function (return $d)))" data)
(VOProducer "all" admitted-atom-result "(: vhold (-> Atom Atom)) (= (vhold $x) $x) " "(let $d (catch (Error value (Fault datum))) (vhold $d))" data)
(VOProducer "all" admitted-expression-result "(: vhold (-> Expression Expression)) (= (vhold $x) $x) " "(let $d (catch (Error value (Fault datum))) (vhold $d))" data)
(VOProducer "all" admitted-several-arguments "(: vhold (-> Atom Atom Atom)) (= (vhold $a $b) $b) " "(let $d (catch (Error value (Fault datum))) (vhold ignored $d))" data)
(VOProducer "all" admitted-delimited-result "(: vhold (-> Atom Atom)) (= (vhold $x) (function (return $x))) " "(let $d (catch (Error value (Fault datum))) (vhold $d))" data)
(VOProducer "he" admitted-substitution "" "(let $d (catch (Error $x (Fault datum))) (atom-subst value $x $d))" data)
(VOProducer "all" admitted-native-projection "" "(let $d (catch (Error value (Fault datum))) (index-atom [$d] 0))" data)

(VOConsumer "let" "(let $d " " (Box $d))")
(VOConsumer "chain" "(chain " " $d (Box $d))")
(VOConsumer "case" "(case " " (($d (Box $d))))")
(VOConsumer "capture" "(let $d (capture " ") (Box $d))")
(VOConsumer "discard" "(let $d " " reached)")

(= (vo:check $binary $language $route (OutputCase $name $consumer $declarations $source $origin $before $after))
   (let* (($code (str:join "" ("!(ai:experiment failure-values) " $declarations "!" $before $source $after)))
          ($term (if (== $origin source) "(Error value (Fault datum))"
                    (if (== $consumer "discard") "reached" "(Box (Error value (Fault datum)))")))
          ($expected (if (== $language "he") (str:join "" ("[()]\n[" $term "]\n"))
                           (str:join "" ("()\n" $term "\n")))))
     (case (proc:run ("/usr/bin/env" $route $binary "--lang" $language "--profile" "ai" "-e" $code)
                     "." inherit 15000 1048576)
       (((proc:exited 0 $actual "")
          (if (== $actual $expected) 0
            (let $shown (println! (ValueOutputMismatch $language $route $name $consumer $expected $actual)) 1)))
        ($bad (let $shown (println! (ValueOutputExecutionFailed $language $route $name $consumer $bad)) 1))))))
(= (vo:walk $binary $language $route $cases $index $bad)
   (if (== $index (size-atom $cases)) (ValueOutputResults $language $route $index $bad)
     (let $failure (vo:check $binary $language $route (index-atom $cases $index))
       (vo:walk $binary $language $route $cases (+ $index 1) (+ $bad $failure)))))
(= (vo:run $binary $language $route)
   (let $cases (collapse
          (let (Producer $scope $name $declarations $source $origin)
               (match &self (VOProducer $scope $name $declarations $source $origin)
                    (Producer $scope $name $declarations $source $origin))
            (if (or (== $scope "all") (== $scope $language))
              (match &self (VOConsumer $consumer $before $after)
                (OutputCase $name $consumer $declarations $source $origin $before $after))
              (superpose ()))))
     (vo:walk $binary $language $route $cases 0 0)))
