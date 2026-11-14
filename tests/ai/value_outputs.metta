; A value output must keep its role across consumers. Held inputs are
; deliberately not completed here; quotation-opening tests are separate.
!(import! &self "./he_contract.metta")

(VOProducer "all" explicit-return "" "(function (return (Error value (Fault datum))))")
(VOProducer "all" atom-result "(: vhold (-> Atom Atom)) (= (vhold $x) $x) " "(vhold (Error value (Fault datum)))")
; HE holds Expression inputs; PeTTa evaluates them, so its corresponding
; value-output control obtains an admitted datum first.
(VOProducer "he" expression-result "(: vhold (-> Expression Expression)) (= (vhold $x) $x) " "(vhold (Error value (Fault datum)))")
(VOProducer "petta" expression-admitted-result "(: vhold (-> Expression Expression)) (= (vhold $x) $x) " "(vhold (catch (Error value (Fault datum))))")
(VOProducer "all" several-arguments "(: vhold (-> Atom Atom Atom)) (= (vhold $a $b) $b) " "(vhold ignored (Error value (Fault datum)))")
(VOProducer "all" delimited-result "(: vhold (-> Atom Atom)) (= (vhold $x) (function (return $x))) " "(vhold (Error value (Fault datum)))")
(VOProducer "all" authored-atom-result "(: vhold (-> Atom)) (= (vhold) (Error value (Fault datum))) " "(vhold)")
(VOProducer "all" typed-metta "" "(metta (Error value (Fault datum)) Atom &self)")
; This is an HE stdlib operation, not an implicit PeTTa import.
(VOProducer "he" substitution-result "" "(atom-subst value $x (Error $x (Fault datum)))")
(VOProducer "all" native-data "" "(index-atom [(Error value (Fault datum))] 0)")
(VOProducer "all" caught-data "" "(catch (Error value (Fault datum)))")
(VOProducer "all" constructed-data "" "(cons-atom Error (value (Fault datum)))")
(VOProducer "all" stored-data "(VRow (Error value (Fault datum))) " "(match &self (VRow $x) $x)")

(VOConsumer "let" "(let $d " " (Box $d))")
(VOConsumer "chain" "(chain " " $d (Box $d))")
(VOConsumer "case" "(case " " (($d (Box $d))))")
(VOConsumer "capture" "(let $d (capture " ") (Box $d))")

(= (vo:check $binary $language $route (OutputCase $name $consumer $declarations $source $before $after))
   (let* (($code (str:join "" ("!(ai:experiment failure-values) " $declarations "!" $before $source $after)))
          ($expected (if (== $language "he") "[()]\n[(Box (Error value (Fault datum)))]\n"
                           "()\n(Box (Error value (Fault datum)))\n")))
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
          (let (Producer $scope $name $declarations $source)
               (match &self (VOProducer $scope $name $declarations $source)
                    (Producer $scope $name $declarations $source))
            (if (or (== $scope "all") (== $scope $language))
              (match &self (VOConsumer $consumer $before $after)
                (OutputCase $name $consumer $declarations $source $before $after))
              (superpose ()))))
     (vo:walk $binary $language $route $cases 0 0)))
