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
   (let* (($p (ais:fixtures $binary "petta" "CETTA_PETTA_SEARCH_MACHINE=1"
              ("failure_values" "positions" "effects" "library_observers") $cwd 0))
          ($r (ais:fixtures $binary "petta" "CETTA_PETTA_SEARCH_MACHINE=0"
              ("failure_values" "positions" "effects") $cwd 0))
          ($h (ais:fixtures $binary "he" "CETTA_PETTA_SEARCH_MACHINE=1"
              ("failure_values" "positions" "effects" "library_observers") $cwd 0))
          ($t (ais:fixtures $binary "petta" "CETTA_PETTA_TRANSLATOR_EXPANSION=0"
              ("failure_values" "positions" "effects" "library_observers") $cwd 0))
          ($mc (ais:fixtures $binary "petta" "CETTA_PETTA_SEARCH_MACHINE=1" ("macro_capture") $cwd 0))
          ($mt (ais:fixtures $binary "petta" "CETTA_PETTA_TRANSLATOR_EXPANSION=0" ("macro_capture") $cwd 0))
          ($pm (ais:matrix $binary "petta" "CETTA_PETTA_SEARCH_MACHINE=1"))
          ($rm (ais:matrix $binary "petta" "CETTA_PETTA_SEARCH_MACHINE=0"))
          ($hm (ais:matrix $binary "he" "CETTA_PETTA_SEARCH_MACHINE=1"))
          ($tm (ais:matrix $binary "petta" "CETTA_PETTA_TRANSLATOR_EXPANSION=0")))
     (case ($p $r $h $t $mc $mt (ah:run $binary))
       (((4 3 4 4 1 1 (HostControlsPass 13)) (AISuitePass 17 3968 13))
        ($bad (let $shown (println! (SuiteCountFailed $bad)) (system:exit 1)))))))
