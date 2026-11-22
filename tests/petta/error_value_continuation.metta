; An Error that is a value is an ordinary answer, so a file goes on after
; one: a literal Error, one a function builds, one a function passes through,
; and an error caught at top level.  Only an uncaught error stops a file.
(= (mkerr $x) (Error $x oops))
(= (myid $x) $x)
!(Error foo bar)
!(println! after-literal)
!(mkerr 5)
!(println! after-built)
!(myid (Error a b))
!(println! after-passed)
!(let (Error $formal $context) (catch (/ 1 0)) (Error $formal caught))
!(println! done)
