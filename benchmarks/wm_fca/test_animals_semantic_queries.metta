!(import! &self ./animals_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this published matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-animals-state)))
     (size-atom $observations))
   385)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-state) animals object_000_alligator attribute_000_eggs)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-state) animals object_000_alligator attribute_001_nocturnal)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-state) another-context
     object_000_alligator attribute_001_nocturnal)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-animals-state)
            animals WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_001_nocturnal)) (attribute_001_nocturnal attribute_006_airbreather))
       (and
         (== (wm-fca-index-closure $index (attribute_000_eggs)) (attribute_000_eggs))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_001_nocturnal) (attribute_006_airbreather)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_eggs) (attribute_001_nocturnal))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-animals-state) animals object_000_alligator attribute_001_nocturnal)
   ((WMFCAObservation
      animals object_000_alligator attribute_001_nocturnal WMFalse
      animals-cell-000-001 fcatools-contexts-9306d256 animals-published-matrix)))
