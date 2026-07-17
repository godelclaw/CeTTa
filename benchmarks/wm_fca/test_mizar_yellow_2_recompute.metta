!(import! &self ./mizar_yellow_2_context.metta)

(= (wm-fca-mizar_yellow_2-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_yellow_2-state) (WMFCAScopeStamp mizar_yellow_2-cell-000-005)))
(= (wm-fca-mizar_yellow_2-recompute-restored)
   (wm-fca-remember
     (wm-fca-mizar_yellow_2-recompute-forgotten)
     (WMFCAObservation
       mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr WMTrue
       mizar_yellow_2-cell-000-005 mettapedia-mizar-family-f93a93f7 mizar-yellow-2-extraction)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_yellow_2-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_2-state)
              mizar_yellow_2 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_yellow_2 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
