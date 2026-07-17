!(import! &self ./bob_ross_event_context.metta)

; Prefix 14 forces the immutable event fold but performs no FCA query.  This
; fixture separates update replay from the query assertions in the full gate.

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-bob_ross-event-state-14))
   0)
!(assertEqual
   (let $events (eval (wm-fca-state-events (wm-fca-bob_ross-event-state-14)))
     (size-atom $events))
   14)
