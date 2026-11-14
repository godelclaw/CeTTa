; Library-authored returns are not observers. A failure must stop the
; continuation, while admitted data may pass through the same return path.
!(import! &self "./he_contract.metta")

(LibraryOrigin cast-refusal
 "!(let $r (type-cast 1 String &self) (let $u (add-atom &self escaped-cast) reached)) !(collapse (match &self escaped-cast reached))"
 "[(Error 1 (Fault BadType))]\n[()]\n")
(LibraryOrigin pair-refusal
 "!(let $r (first-from-pair nope) (let $u (add-atom &self escaped-pair) reached)) !(collapse (match &self escaped-pair reached))"
 "[(Error (first-from-pair nope) (Fault \"incorrect pair format\"))]\n[()]\n")
(LibraryOrigin pair-data
 "!(let $d (catch (Error value (Fault datum))) (let $r (first-from-pair ($d 7)) (Box $r)))"
 "[(Box (Error value (Fault datum)))]\n")

(= (lo:check $binary $route (LibraryCase $name $source $wanted))
   (let $program (str:concat "!(ai:experiment failure-values) " $source)
     (case (proc:run ("/usr/bin/env" $route $binary "--lang" "he" "--profile" "ai" "-e" $program)
                     "." inherit 10000 1048576)
       (((proc:exited 0 $actual "")
          (if (== $actual (str:concat "[()]\n" $wanted)) 0
            (let $shown (println! (LibraryOriginMismatch $route $name $wanted $actual)) 1)))
        ($bad (let $shown (println! (LibraryOriginExecutionFailed $route $name $bad)) 1))))))
(= (lo:walk $binary $route $cases $index $bad)
   (if (== $index (size-atom $cases)) (LibraryOriginResults $route $index $bad)
     (let $failure (lo:check $binary $route (index-atom $cases $index))
       (lo:walk $binary $route $cases (+ $index 1) (+ $bad $failure)))))
(= (lo:run $binary $route)
   (let $cases (collapse (match &self (LibraryOrigin $name $source $wanted)
                              (LibraryCase $name $source $wanted)))
     (lo:walk $binary $route $cases 0 0)))
