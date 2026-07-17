!(import! &self ../lib/lib_wm_fca.metta)

(= (certificate-state)
   (WMFCAState
     (o1 o2)
     (a b)
     ((WMFCAObservation
        certificate-context o1 a WMTrue
        stamp-o1-a source-1 group-1)
      (WMFCAObservation
        certificate-context o1 b WMTrue
        stamp-o1-b source-1 group-1)
      (WMFCAObservation
        certificate-context o2 a WMTrue
        stamp-o2-a source-2 group-2)
      (WMFCAObservation
        certificate-context o2 b WMFalse
        stamp-o2-b source-2 group-2))))

(= (certificate-closure)
   (wm-fca-certify-closure
     (certificate-state) certificate-context
     WMFCAExactStatusGate (b)))

; Positive closure certificate and its two explicit Galois stages.
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-verify-closure-certificate $certificate))
   True)
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-query $certificate))
   (b))
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-extent $certificate))
   (o1))
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-closure $certificate))
   (a b))
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-history $certificate))
   WMFCAHistoryUnavailable)

; The certificate exposes exactly the cell-query boundary.  All objects at a
; queried attribute and all attributes at an extent object participate.
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-required-cell?
       $certificate o1 a))
   True)
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-required-cell?
       $certificate o2 b))
   True)
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-required-cell?
       $certificate o2 a))
   False)
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-explain-required-cell
       $certificate o1 a))
   ((WMFCAObservation
      certificate-context o1 a WMTrue
      stamp-o1-a source-1 group-1)))
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-explain-required-cell
       $certificate o2 b))
   ((WMFCAObservation
      certificate-context o2 b WMFalse
      stamp-o2-b source-2 group-2)))
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (wm-fca-closure-certificate-explain-required-cell
       $certificate o2 a))
   ())

; A changed extent cannot pass replay verification.
!(assertEqual
   (let $certificate (eval (certificate-closure))
     (let $index
          (eval (wm-fca-closure-certificate-index $certificate))
       (wm-fca-verify-closure-certificate
         (WMFCAClosureCertificate
           $index (b) (o1 o2) (a b)))))
   False)

(= (certificate-positive-implication)
   (wm-fca-certify-implication
     (certificate-state) certificate-context
     WMFCAExactStatusGate
     (WMFCAImplication (b) (a))))

(= (certificate-negative-implication)
   (wm-fca-certify-implication
     (certificate-state) certificate-context
     WMFCAExactStatusGate
     (WMFCAImplication (a) (b))))

; Both a holding and a non-holding implication have replayable certificates.
!(assertEqual
   (let $certificate (eval (certificate-positive-implication))
     (wm-fca-implication-certificate-result $certificate))
   True)
!(assertEqual
   (let $certificate (eval (certificate-positive-implication))
     (wm-fca-verify-implication-certificate $certificate))
   True)
!(assertEqual
   (let $certificate (eval (certificate-negative-implication))
     (wm-fca-implication-certificate-result $certificate))
   False)
!(assertEqual
   (let $certificate (eval (certificate-negative-implication))
     (wm-fca-verify-implication-certificate $certificate))
   True)
!(assertEqual
   (let $certificate (eval (certificate-negative-implication))
     (let $closureCertificate
          (eval
            (wm-fca-implication-certificate-closure
              $certificate))
       (wm-fca-verify-implication-certificate
         (WMFCAImplicationCertificate
           (WMFCAImplication (a) (b))
           $closureCertificate True))))
   False)

(= (certificate-positive-concept)
   (wm-fca-certify-concept
     (certificate-state) certificate-context
     WMFCAExactStatusGate
     (WMFCAConcept (o1) (a b))))

(= (certificate-negative-concept)
   (wm-fca-certify-concept
     (certificate-state) certificate-context
     WMFCAExactStatusGate
     (WMFCAConcept (o1 o2) (a b))))

; Concept membership is certified from the same extent/closure derivation.
!(assertEqual
   (let $certificate (eval (certificate-positive-concept))
     (wm-fca-concept-certificate-result $certificate))
   True)
!(assertEqual
   (let $certificate (eval (certificate-positive-concept))
     (wm-fca-verify-concept-certificate $certificate))
   True)
!(assertEqual
   (let $certificate (eval (certificate-negative-concept))
     (wm-fca-concept-certificate-result $certificate))
   False)
!(assertEqual
   (let $certificate (eval (certificate-negative-concept))
     (wm-fca-verify-concept-certificate $certificate))
   True)
!(assertEqual
   (let $certificate (eval (certificate-negative-concept))
     (let $closureCertificate
          (eval
            (wm-fca-concept-certificate-closure
              $certificate))
       (wm-fca-verify-concept-certificate
         (WMFCAConceptCertificate
           (WMFCAConcept (o1 o2) (a b))
           $closureCertificate True))))
   False)

; Event-backed states preserve the actual immutable update log in the chain.
(= (certificate-binary-state)
   (WMFCACompleteBinaryState
     (o1 o2) (a b)
     ((WMFCABinaryRow o1 "11")
      (WMFCABinaryRow o2 "10"))
     certificate-context binary-source binary-group))

(= (certificate-event-state)
   (wm-fca-remember
     (certificate-binary-state)
     (WMFCAObservation
       certificate-context o2 b WMUnknown
       review-stamp review-source review-group)))

!(assertEqual
   (let $certificate
        (eval
          (wm-fca-certify-closure
            (certificate-event-state) certificate-context
            WMFCAExactStatusGate (b)))
     (wm-fca-closure-certificate-history $certificate))
   (WMFCAEventHistory
     ((WMFCARememberEvent
        (WMFCAObservation
          certificate-context o2 b WMUnknown
          review-stamp review-source review-group)))))

; The ordinary query surface returns the same typed certificate.
!(assertEqual
   (let $direct (eval (certificate-closure))
     (wm-fca-query
       (certificate-state)
       (WMFCAClosureCertificateQuery
         certificate-context WMFCAExactStatusGate (b))))
   (WMFCAClosureCertificateValue (certificate-closure)))
