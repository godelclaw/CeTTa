!(ai:experiment failure-values)
; Runtime and expand-once translator routes must open syntax before replacing
; its holes with completed values. A captured value never becomes source.
(: ai:box-syntax (-> Atom %Undefined%))
(= (ai:box-syntax $source) (quote (Box $source)))
!(add-translator-rule! ai:box-syntax)
!(ai:box-syntax (+ 1 2))
!(let $data (quote (+ 1 2)) (ai:box-syntax $data))
!(let $data (catch (Error captured (Fault data))) (ai:box-syntax $data))
!(ai:box-syntax (Error executed (Fault bad)))
; Several matching equations force the normal per-call fallback even when
; expand-once is enabled. Both alternatives retain their occurrences.
(: ai:choose-template (-> Atom %Undefined%))
(= (ai:choose-template $source) (quote (Left $source)))
(= (ai:choose-template $source) (quote (Right $source)))
!(add-translator-rule! ai:choose-template)
!(collapse (let $data (catch (Error captured (Fault data))) (ai:choose-template $data)))
!(collapse (ai:choose-template (Error executed (Fault bad))))
