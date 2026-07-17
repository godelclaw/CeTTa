!(import! &self ./mizar_waybel_1_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-state) mizar_waybel_1 object_000_definition_1 attribute_002_function)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-state) mizar_waybel_1 object_000_definition_1 attribute_000_boolean)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_waybel_1-state) mizar_waybel_1 object_000_definition_1 attribute_000_boolean)
   ((WMFCAObservation
      mizar_waybel_1 object_000_definition_1 attribute_000_boolean WMFalse
      mizar_waybel_1-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-state) another-context
     object_000_definition_1 attribute_000_boolean)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_waybel_1-state)
              (wm-fca-mizar_waybel_1-state))))
     (size-atom $observations))
   1904)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_waybel_1-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_waybel_1-state) (WMFCAScopeStamp mizar_waybel_1-cell-000-002)))
(= (wm-fca-mizar_waybel_1-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_waybel_1-update-test-forgotten)
     (WMFCAObservation
       mizar_waybel_1 object_000_definition_1 attribute_002_function WMTrue
       mizar_waybel_1-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-update-test-forgotten)
     mizar_waybel_1 object_000_definition_1 attribute_002_function)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-update-test-restored)
     mizar_waybel_1 object_000_definition_1 attribute_002_function)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_waybel_1-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_waybel_1-state)
              mizar_waybel_1 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_waybel_1 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
