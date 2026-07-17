!(import! &self ./mizar_yellow_0_context.metta)

(= (wm-fca-mizar_yellow_0-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_yellow_0-state) (WMFCAScopeStamp mizar_yellow_0-cell-000-001)))
(= (wm-fca-mizar_yellow_0-recompute-restored)
   (wm-fca-remember
     (wm-fca-mizar_yellow_0-recompute-forgotten)
     (WMFCAObservation
       mizar_yellow_0 object_000_scheme_1 attribute_001_relstr WMTrue
       mizar_yellow_0-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-yellow-0-extraction)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_yellow_0-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_0-state)
              mizar_yellow_0 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_yellow_0 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
