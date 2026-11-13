; An ordinary library observes through explicit catch, not an engine list
; of privileged function names. Direct strict arguments still propagate.
!(import! &self (library outcome))
!(out:kind (catch (Error first (Forbidden policy))))
!(out:reify (catch (Error first (Fault bad))))
!(out:reflect (Failed first Fault bad))
!(out:where (catch (Error (+ 1 2) (Fault (+ 3 4)))))
!(out:detail (catch (Error (+ 1 2) (Fault (+ 3 4)))))
!(let $value (out:reflect (Failed first Incomplete pending)) unreachable)
!(let $value (catch (Error first (Fault bad))) (Box $value))
!(out:kind (Error first (Fault bad)))
