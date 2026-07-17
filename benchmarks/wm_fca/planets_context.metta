; Wille's classical Planets formal context as published by fcaR 2.0.0.
; Source: https://malaga-fca-group.github.io/fcaR/articles/concept_lattice.html
;
; The context is complete: all 9 x 7 cells are explicit observations.  Zeroes
; are WMFalse, never WMMissing.  One source/dependence group records that this
; is a single published matrix rather than 63 independent measurements.

!(import! &self lib_wm_fca)

(= (wm-fca-planets-objects)
   (Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune Pluto))

(= (wm-fca-planets-attributes)
   (small medium large near far moon no_moon))

(= (wm-fca-planets-state)
   (WMFCAState
     (Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune Pluto)
     (small medium large near far moon no_moon)
     (
      (WMFCAObservation planets Mercury small WMTrue
        planets-Mercury-small fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mercury medium WMFalse
        planets-Mercury-medium fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mercury large WMFalse
        planets-Mercury-large fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mercury near WMTrue
        planets-Mercury-near fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mercury far WMFalse
        planets-Mercury-far fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mercury moon WMFalse
        planets-Mercury-moon fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mercury no_moon WMTrue
        planets-Mercury-no_moon fcaR-v2.0.0-planets fcaR-planets-matrix)

      (WMFCAObservation planets Venus small WMTrue
        planets-Venus-small fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Venus medium WMFalse
        planets-Venus-medium fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Venus large WMFalse
        planets-Venus-large fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Venus near WMTrue
        planets-Venus-near fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Venus far WMFalse
        planets-Venus-far fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Venus moon WMFalse
        planets-Venus-moon fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Venus no_moon WMTrue
        planets-Venus-no_moon fcaR-v2.0.0-planets fcaR-planets-matrix)

      (WMFCAObservation planets Earth small WMTrue
        planets-Earth-small fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Earth medium WMFalse
        planets-Earth-medium fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Earth large WMFalse
        planets-Earth-large fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Earth near WMTrue
        planets-Earth-near fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Earth far WMFalse
        planets-Earth-far fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Earth moon WMTrue
        planets-Earth-moon fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Earth no_moon WMFalse
        planets-Earth-no_moon fcaR-v2.0.0-planets fcaR-planets-matrix)

      (WMFCAObservation planets Mars small WMTrue
        planets-Mars-small fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mars medium WMFalse
        planets-Mars-medium fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mars large WMFalse
        planets-Mars-large fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mars near WMTrue
        planets-Mars-near fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mars far WMFalse
        planets-Mars-far fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mars moon WMTrue
        planets-Mars-moon fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Mars no_moon WMFalse
        planets-Mars-no_moon fcaR-v2.0.0-planets fcaR-planets-matrix)

      (WMFCAObservation planets Jupiter small WMFalse
        planets-Jupiter-small fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Jupiter medium WMFalse
        planets-Jupiter-medium fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Jupiter large WMTrue
        planets-Jupiter-large fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Jupiter near WMFalse
        planets-Jupiter-near fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Jupiter far WMTrue
        planets-Jupiter-far fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Jupiter moon WMTrue
        planets-Jupiter-moon fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Jupiter no_moon WMFalse
        planets-Jupiter-no_moon fcaR-v2.0.0-planets fcaR-planets-matrix)

      (WMFCAObservation planets Saturn small WMFalse
        planets-Saturn-small fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Saturn medium WMFalse
        planets-Saturn-medium fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Saturn large WMTrue
        planets-Saturn-large fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Saturn near WMFalse
        planets-Saturn-near fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Saturn far WMTrue
        planets-Saturn-far fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Saturn moon WMTrue
        planets-Saturn-moon fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Saturn no_moon WMFalse
        planets-Saturn-no_moon fcaR-v2.0.0-planets fcaR-planets-matrix)

      (WMFCAObservation planets Uranus small WMFalse
        planets-Uranus-small fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Uranus medium WMTrue
        planets-Uranus-medium fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Uranus large WMFalse
        planets-Uranus-large fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Uranus near WMFalse
        planets-Uranus-near fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Uranus far WMTrue
        planets-Uranus-far fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Uranus moon WMTrue
        planets-Uranus-moon fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Uranus no_moon WMFalse
        planets-Uranus-no_moon fcaR-v2.0.0-planets fcaR-planets-matrix)

      (WMFCAObservation planets Neptune small WMFalse
        planets-Neptune-small fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Neptune medium WMTrue
        planets-Neptune-medium fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Neptune large WMFalse
        planets-Neptune-large fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Neptune near WMFalse
        planets-Neptune-near fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Neptune far WMTrue
        planets-Neptune-far fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Neptune moon WMTrue
        planets-Neptune-moon fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Neptune no_moon WMFalse
        planets-Neptune-no_moon fcaR-v2.0.0-planets fcaR-planets-matrix)

      (WMFCAObservation planets Pluto small WMTrue
        planets-Pluto-small fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Pluto medium WMFalse
        planets-Pluto-medium fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Pluto large WMFalse
        planets-Pluto-large fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Pluto near WMFalse
        planets-Pluto-near fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Pluto far WMTrue
        planets-Pluto-far fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Pluto moon WMTrue
        planets-Pluto-moon fcaR-v2.0.0-planets fcaR-planets-matrix)
      (WMFCAObservation planets Pluto no_moon WMFalse
        planets-Pluto-no_moon fcaR-v2.0.0-planets fcaR-planets-matrix))))

(= (wm-fca-planets-published-intents)
   (()
    (moon)
    (far moon)
    (large far moon)
    (medium far moon)
    (small)
    (small moon)
    (small far moon)
    (small near)
    (small near no_moon)
    (small near moon)
    (small medium large near far moon no_moon)))

(= (wm-fca-planets-published-concepts)
   ((WMFCAConcept
      (Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune Pluto) ())
    (WMFCAConcept
      (Earth Mars Jupiter Saturn Uranus Neptune Pluto) (moon))
    (WMFCAConcept
      (Jupiter Saturn Uranus Neptune Pluto) (far moon))
    (WMFCAConcept (Jupiter Saturn) (large far moon))
    (WMFCAConcept (Uranus Neptune) (medium far moon))
    (WMFCAConcept (Mercury Venus Earth Mars Pluto) (small))
    (WMFCAConcept (Earth Mars Pluto) (small moon))
    (WMFCAConcept (Pluto) (small far moon))
    (WMFCAConcept (Mercury Venus Earth Mars) (small near))
    (WMFCAConcept (Mercury Venus) (small near no_moon))
    (WMFCAConcept (Earth Mars) (small near moon))
    (WMFCAConcept () (small medium large near far moon no_moon))))

(= (wm-fca-planets-published-basis)
   ((WMFCAImplication (no_moon) (small near))
    (WMFCAImplication (far) (moon))
    (WMFCAImplication (near) (small))
    (WMFCAImplication (large) (far moon))
    (WMFCAImplication (medium) (far moon))
    (WMFCAImplication
      (medium large far moon) (small near no_moon))
    (WMFCAImplication
      (small near moon no_moon) (medium large far))
    (WMFCAImplication
      (small near far moon) (medium large no_moon))
    (WMFCAImplication
      (small large far moon) (medium near no_moon))
    (WMFCAImplication
      (small medium far moon) (large near no_moon))))

; Cover direction follows intent inclusion: general intent -> specific intent.
(= (wm-fca-planets-published-covers)
   ((WMFCACover () (moon))
    (WMFCACover () (small))
    (WMFCACover (moon) (far moon))
    (WMFCACover (moon) (small moon))
    (WMFCACover (far moon) (large far moon))
    (WMFCACover (far moon) (medium far moon))
    (WMFCACover (far moon) (small far moon))
    (WMFCACover
      (large far moon) (small medium large near far moon no_moon))
    (WMFCACover
      (medium far moon) (small medium large near far moon no_moon))
    (WMFCACover (small) (small moon))
    (WMFCACover (small) (small near))
    (WMFCACover (small moon) (small far moon))
    (WMFCACover (small moon) (small near moon))
    (WMFCACover
      (small far moon) (small medium large near far moon no_moon))
    (WMFCACover (small near) (small near no_moon))
    (WMFCACover (small near) (small near moon))
    (WMFCACover
      (small near no_moon) (small medium large near far moon no_moon))
    (WMFCACover
      (small near moon) (small medium large near far moon no_moon))))
