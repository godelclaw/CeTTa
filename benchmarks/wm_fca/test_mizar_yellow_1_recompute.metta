!(import! &self ./mizar_yellow_1_context.metta)

(= (wm-fca-mizar_yellow_1-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_yellow_1-state) (WMFCAScopeStamp mizar_yellow_1-cell-000-001)))
(= (wm-fca-mizar_yellow_1-recompute-restored)
   (wm-fca-remember
     (wm-fca-mizar_yellow_1-recompute-forgotten)
     (WMFCAObservation
       mizar_yellow_1 object_000_definition_1 attribute_001_inclposet WMTrue
       mizar_yellow_1-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-yellow-1-extraction)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_yellow_1-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_1-state)
              mizar_yellow_1 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_yellow_1 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
