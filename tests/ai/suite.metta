; One native runner for release binaries and isolated qualification builds.
!(import! &self "./check_fixture.metta")
!(import! &self "./host_controls.metta")
!(import! &self "./kind_matrix.metta")

(= (ais:fixtures $binary $language $route $names $cwd $count)
   (if (== $names ()) $count
     (let* (($name (car-atom $names)) ($rest (cdr-atom $names))
            ($fixture (str:join "" ("tests/ai/" $name ".metta")))
            ($expected (str:join "" ("tests/ai/" $name "." $language ".expected"))))
       (case (ai-test:check $binary $language $route $fixture $expected $cwd)
         (((Pass $language $route $fixture)
            (ais:fixtures $binary $language $route $rest $cwd (+ $count 1)))
          ($bad (let $shown (println! (SuiteFixtureFailed $bad)) (system:exit 1))))))))
(= (ais:matrix $binary $language $route)
   (case ((km:run $binary $language $route) (km:nested $binary $language $route))
     ((((MatrixPass $language $route 92) (NestedMatrixPass $language $route 900)) ())
      ($bad (let $shown (println! (SuiteMatrixFailed $bad)) (system:exit 1))))))
(= (ais:run $binary $cwd)
   (let* (($p (ais:fixtures $binary "petta" "CETTA_PETTA_TRANSLATOR_EXPANSION=1"
              ("failure_values" "positions" "effects" "library_observers" "macro_capture" "review_regressions") $cwd 0))
          ($t (ais:fixtures $binary "petta" "CETTA_PETTA_TRANSLATOR_EXPANSION=0"
              ("failure_values" "positions" "effects" "library_observers" "macro_capture" "review_regressions") $cwd 0))
          ($pm (ais:matrix $binary "petta" "CETTA_PETTA_TRANSLATOR_EXPANSION=1"))
          ($tm (ais:matrix $binary "petta" "CETTA_PETTA_TRANSLATOR_EXPANSION=0")))
     (case ($p $t (ah:run $binary))
       (((6 6 (HostControlsPass 25)) (AISuitePass 12 1984 25))
        ($bad (let $shown (println! (SuiteCountFailed $bad)) (system:exit 1)))))))
