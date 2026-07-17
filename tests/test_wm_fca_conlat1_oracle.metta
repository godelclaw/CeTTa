; conlat_1 exact-reconstruction gate (generated; do not edit by hand).
; Oracle: conlat_1_external_fca_check.json -> bruteforce == external == 17 concepts.
; Objects: 12  Attributes: 9  Incident cells: 41
!(import! &self lib_wm_fca)

(= (conlat1-state)
   (WMFCAState
     (definition_1 registration_2 definition_2 definition_3 registration_4 definition_4 notation_1 definition_5 definition_6 theorem_1 theorem_2 theorem_3)
     (Attribute AttributeDerivation ContextStr FormalContext Function Information ObjectDerivation Subset is-connected-with)
     (
    (WMFCAObservation conlat1 definition_1 ContextStr WMTrue st-0 mizar conlat1)
    (WMFCAObservation conlat1 definition_1 Information WMTrue st-1 mizar conlat1)
    (WMFCAObservation conlat1 registration_2 ContextStr WMTrue st-2 mizar conlat1)
    (WMFCAObservation conlat1 definition_2 ContextStr WMTrue st-3 mizar conlat1)
    (WMFCAObservation conlat1 definition_2 FormalContext WMTrue st-4 mizar conlat1)
    (WMFCAObservation conlat1 definition_3 Attribute WMTrue st-5 mizar conlat1)
    (WMFCAObservation conlat1 registration_4 Subset WMTrue st-6 mizar conlat1)
    (WMFCAObservation conlat1 definition_4 Attribute WMTrue st-7 mizar conlat1)
    (WMFCAObservation conlat1 definition_4 FormalContext WMTrue st-8 mizar conlat1)
    (WMFCAObservation conlat1 definition_4 Information WMTrue st-9 mizar conlat1)
    (WMFCAObservation conlat1 definition_4 is-connected-with WMTrue st-10 mizar conlat1)
    (WMFCAObservation conlat1 notation_1 Attribute WMTrue st-11 mizar conlat1)
    (WMFCAObservation conlat1 notation_1 FormalContext WMTrue st-12 mizar conlat1)
    (WMFCAObservation conlat1 notation_1 is-connected-with WMTrue st-13 mizar conlat1)
    (WMFCAObservation conlat1 definition_5 Attribute WMTrue st-14 mizar conlat1)
    (WMFCAObservation conlat1 definition_5 FormalContext WMTrue st-15 mizar conlat1)
    (WMFCAObservation conlat1 definition_5 Function WMTrue st-16 mizar conlat1)
    (WMFCAObservation conlat1 definition_5 ObjectDerivation WMTrue st-17 mizar conlat1)
    (WMFCAObservation conlat1 definition_5 Subset WMTrue st-18 mizar conlat1)
    (WMFCAObservation conlat1 definition_5 is-connected-with WMTrue st-19 mizar conlat1)
    (WMFCAObservation conlat1 definition_6 Attribute WMTrue st-20 mizar conlat1)
    (WMFCAObservation conlat1 definition_6 AttributeDerivation WMTrue st-21 mizar conlat1)
    (WMFCAObservation conlat1 definition_6 FormalContext WMTrue st-22 mizar conlat1)
    (WMFCAObservation conlat1 definition_6 Function WMTrue st-23 mizar conlat1)
    (WMFCAObservation conlat1 definition_6 Subset WMTrue st-24 mizar conlat1)
    (WMFCAObservation conlat1 definition_6 is-connected-with WMTrue st-25 mizar conlat1)
    (WMFCAObservation conlat1 theorem_1 Attribute WMTrue st-26 mizar conlat1)
    (WMFCAObservation conlat1 theorem_1 FormalContext WMTrue st-27 mizar conlat1)
    (WMFCAObservation conlat1 theorem_1 ObjectDerivation WMTrue st-28 mizar conlat1)
    (WMFCAObservation conlat1 theorem_1 Subset WMTrue st-29 mizar conlat1)
    (WMFCAObservation conlat1 theorem_1 is-connected-with WMTrue st-30 mizar conlat1)
    (WMFCAObservation conlat1 theorem_2 Attribute WMTrue st-31 mizar conlat1)
    (WMFCAObservation conlat1 theorem_2 AttributeDerivation WMTrue st-32 mizar conlat1)
    (WMFCAObservation conlat1 theorem_2 FormalContext WMTrue st-33 mizar conlat1)
    (WMFCAObservation conlat1 theorem_2 Subset WMTrue st-34 mizar conlat1)
    (WMFCAObservation conlat1 theorem_2 is-connected-with WMTrue st-35 mizar conlat1)
    (WMFCAObservation conlat1 theorem_3 Attribute WMTrue st-36 mizar conlat1)
    (WMFCAObservation conlat1 theorem_3 FormalContext WMTrue st-37 mizar conlat1)
    (WMFCAObservation conlat1 theorem_3 ObjectDerivation WMTrue st-38 mizar conlat1)
    (WMFCAObservation conlat1 theorem_3 Subset WMTrue st-39 mizar conlat1)
    (WMFCAObservation conlat1 theorem_3 is-connected-with WMTrue st-40 mizar conlat1)
     )))

; Crisp incidence spot-checks (True cells vs a known non-incident cell).
!(assertEqual (wm-fca-crisp-cell? (conlat1-state) conlat1 definition_1 ContextStr) True)
!(assertEqual (wm-fca-crisp-cell? (conlat1-state) conlat1 definition_1 Information) True)
!(assertEqual (wm-fca-crisp-cell? (conlat1-state) conlat1 definition_1 Attribute) False)
!(assertEqual (wm-fca-cell-status (conlat1-state) conlat1 definition_1 Attribute) WMMissing)
!(assertEqual (wm-fca-crisp-cell? (conlat1-state) conlat1 definition_5 is-connected-with) True)

; A derivation spot-check: extent of {Attribute} = objects that have Attribute.
!(let $e (eval (wm-fca-extent (conlat1-state) conlat1 (Attribute))) $e)

; The exact-reconstruction gate: concept count must equal the oracle.
!(assertEqual
   (let $c (eval (wm-fca-concepts-reference (conlat1-state) conlat1))
        (size-atom $c))
   17)
