!(import! &self ./tealady_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this published matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-tealady-state)))
     (size-atom $observations))
   252)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-state) tealady object_000_evelyn attribute_000_attribute_1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-state) tealady object_000_evelyn attribute_006_attribute_7)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-state) another-context
     object_000_evelyn attribute_006_attribute_7)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-tealady-state)
            tealady WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_000_attribute_1)) (attribute_000_attribute_1 attribute_002_attribute_3 attribute_004_attribute_5 attribute_005_attribute_6 attribute_007_attribute_8))
       (and
         (== (wm-fca-index-closure $index (attribute_004_attribute_5)) (attribute_004_attribute_5))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_attribute_1) (attribute_002_attribute_3 attribute_004_attribute_5 attribute_005_attribute_6 attribute_007_attribute_8)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_attribute_1) (attribute_001_attribute_2))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-tealady-state) tealady object_000_evelyn attribute_006_attribute_7)
   ((WMFCAObservation
      tealady object_000_evelyn attribute_006_attribute_7 WMFalse
      tealady-cell-000-006 fcatools-contexts-9306d256 tealady-published-matrix)))
