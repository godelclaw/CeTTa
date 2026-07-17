!(import! &self ./livingbeings_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this published matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-livingbeings-state)))
     (size-atom $observations))
   72)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-state) livingbeings object_000_leech attribute_000_needs_water_to_live)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-state) livingbeings object_000_leech attribute_002_lives_on_land)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-state) another-context
     object_000_leech attribute_002_lives_on_land)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-livingbeings-state)
            livingbeings WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index ()) (attribute_000_needs_water_to_live))
       (and
         (== (wm-fca-index-closure $index (attribute_000_needs_water_to_live)) (attribute_000_needs_water_to_live))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication () (attribute_000_needs_water_to_live)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_needs_water_to_live) (attribute_001_lives_in_water))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-livingbeings-state) livingbeings object_000_leech attribute_002_lives_on_land)
   ((WMFCAObservation
      livingbeings object_000_leech attribute_002_lives_on_land WMFalse
      livingbeings-cell-000-002 fcatools-contexts-9306d256 livingbeings-published-matrix)))
