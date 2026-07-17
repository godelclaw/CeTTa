!(import! &self ./mizar_yellow_3_context.metta)

(= (wm-fca-mizar_yellow_3-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_yellow_3-state) (WMFCAScopeStamp mizar_yellow_3-cell-000-000)))
(= (wm-fca-mizar_yellow_3-recompute-restored)
   (wm-fca-remember
     (wm-fca-mizar_yellow_3-recompute-forgotten)
     (WMFCAObservation
       mizar_yellow_3 object_000_registration_1 attribute_000_relstr WMTrue
       mizar_yellow_3-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-3-extraction)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_yellow_3-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_3-state)
              mizar_yellow_3 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_yellow_3 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
