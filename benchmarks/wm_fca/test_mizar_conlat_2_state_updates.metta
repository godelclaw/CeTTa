!(import! &self ./mizar_conlat_2_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-state) mizar_conlat_2 object_000_definition_1 attribute_000_cp)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-state) mizar_conlat_2 object_000_definition_1 attribute_002_conceptstr)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_conlat_2-state) mizar_conlat_2 object_000_definition_1 attribute_002_conceptstr)
   ((WMFCAObservation
      mizar_conlat_2 object_000_definition_1 attribute_002_conceptstr WMFalse
      mizar_conlat_2-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-conlat-2-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-state) another-context
     object_000_definition_1 attribute_002_conceptstr)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_conlat_2-state)
              (wm-fca-mizar_conlat_2-state))))
     (size-atom $observations))
   243)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_conlat_2-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_conlat_2-state) (WMFCAScopeStamp mizar_conlat_2-cell-000-000)))
(= (wm-fca-mizar_conlat_2-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_conlat_2-update-test-forgotten)
     (WMFCAObservation
       mizar_conlat_2 object_000_definition_1 attribute_000_cp WMTrue
       mizar_conlat_2-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-conlat-2-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-update-test-forgotten)
     mizar_conlat_2 object_000_definition_1 attribute_000_cp)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-update-test-restored)
     mizar_conlat_2 object_000_definition_1 attribute_000_cp)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_conlat_2-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_conlat_2-state)
              mizar_conlat_2 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_conlat_2 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
