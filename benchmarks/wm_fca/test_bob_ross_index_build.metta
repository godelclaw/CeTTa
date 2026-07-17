!(import! &self ./bob_ross_context.metta)

!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-bob_ross-state)
            bob_ross WMFCAExactStatusGate))
     (wm-fca-index-column-count $index))
   67)
