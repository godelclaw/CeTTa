!(import! &self ./mizar_conlat_1_context.metta)

(= (wm-fca-mizar_conlat_1-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_conlat_1-state) (WMFCAScopeStamp mizar_conlat_1-cell-000-015)))
(= (wm-fca-mizar_conlat_1-recompute-restored)
   (wm-fca-remember
     (wm-fca-mizar_conlat_1-recompute-forgotten)
     (WMFCAObservation
       mizar_conlat_1 object_000_definition_1 attribute_015_contextstr WMTrue
       mizar_conlat_1-cell-000-015 mettapedia-mizar-family-f93a93f7 mizar-conlat-1-extraction)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_conlat_1-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_conlat_1-state)
              mizar_conlat_1 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_conlat_1 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
