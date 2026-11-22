; Prolog throw/1 caught at top level continues file execution (split from
; error_value_continuation.metta; requires libswipl).
!(catch (translatePredicate (throw foo)))
!(println! after-caught)
