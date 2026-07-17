!(import! &self ./mizar_lattices_context.metta)

(= (wm-fca-mizar_lattices-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_lattices-state) (WMFCAScopeStamp mizar_lattices-cell-000-001)))
(= (wm-fca-mizar_lattices-recompute-restored)
   (wm-fca-remember
     (wm-fca-mizar_lattices-recompute-forgotten)
     (WMFCAObservation
       mizar_lattices object_000_definition_1 attribute_001_binop WMTrue
       mizar_lattices-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-lattices-extraction)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_lattices-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattices-state)
              mizar_lattices WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_lattices WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
