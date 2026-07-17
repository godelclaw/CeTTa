!(import! &self ./animals_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-state) animals object_000_alligator attribute_000_eggs)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-state) animals object_000_alligator attribute_001_nocturnal)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-animals-state) animals object_000_alligator attribute_001_nocturnal)
   ((WMFCAObservation
      animals object_000_alligator attribute_001_nocturnal WMFalse
      animals-cell-000-001 fcatools-contexts-9306d256 animals-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-state) another-context
     object_000_alligator attribute_001_nocturnal)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-animals-state)
              (wm-fca-animals-state))))
     (size-atom $observations))
   385)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-animals-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-animals-state) (WMFCAScopeStamp animals-cell-000-000)))
(= (wm-fca-animals-update-test-restored)
   (wm-fca-remember
     (wm-fca-animals-update-test-forgotten)
     (WMFCAObservation
       animals object_000_alligator attribute_000_eggs WMTrue
       animals-cell-000-000 fcatools-contexts-9306d256 animals-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-update-test-forgotten)
     animals object_000_alligator attribute_000_eggs)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-update-test-restored)
     animals object_000_alligator attribute_000_eggs)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-animals-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-animals-state)
              animals WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                animals WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
