!(import! &self lib_wm_fca)

(= (wm-fca-minimal-state)
   (WMFCAState
     (object-1)
     (attribute-true attribute-false attribute-missing)
     ((WMFCAObservation
        minimal object-1 attribute-true WMTrue
        stamp-true source-1 group-1)
      (WMFCAObservation
        minimal object-1 attribute-false WMFalse
        stamp-false source-1 group-1))))

; Positive and negative evidence differ from an unobserved cell.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-minimal-state) minimal object-1 attribute-true)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-minimal-state) minimal object-1 attribute-false)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-minimal-state) minimal object-1 attribute-missing)
   WMMissing)

; The crisp FCA projection accepts only positive incidence evidence.
!(assertEqual
   (wm-fca-crisp-cell?
     (wm-fca-minimal-state) minimal object-1 attribute-true)
   True)
!(assertEqual
   (wm-fca-crisp-cell?
     (wm-fca-minimal-state) minimal object-1 attribute-false)
   False)
!(assertEqual
   (wm-fca-crisp-cell?
     (wm-fca-minimal-state) minimal object-1 attribute-missing)
   False)
