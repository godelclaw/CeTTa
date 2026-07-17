; Generated from a pinned public Formal Concept Analysis context.
; Source: https://github.com/fcatools/contexts/blob/9306d256c8a212ffa0c60a52f883a516d8b87b58/contexts/livingbeings_en.cxt
; SHA-256: da4de61a55315b175f166a63b54e26f6c33af5b9ef28e22b554811fae9de790f
;
; The context is complete: all 8 x 9 cells are
; explicit observations.  Matrix zeroes are WMFalse, never WMMissing.  A single
; dependence group records that the cells belong to one published matrix.

!(import! &self lib_wm_fca)

(= (wm-fca-livingbeings-objects)
   (object_000_leech object_001_bream object_002_frog object_003_dog object_004_waterweed object_005_reed object_006_bean object_007_maize))

(= (wm-fca-livingbeings-attributes)
   (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring))

(= (wm-fca-livingbeings-state)
   (WMFCAState
     (object_000_leech object_001_bream object_002_frog object_003_dog object_004_waterweed object_005_reed object_006_bean object_007_maize)
     (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring)
     (
     (WMFCAObservation livingbeings object_000_leech attribute_000_needs_water_to_live WMTrue
  livingbeings-cell-000-000 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_000_leech attribute_001_lives_in_water WMTrue
  livingbeings-cell-000-001 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_000_leech attribute_002_lives_on_land WMFalse
  livingbeings-cell-000-002 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_000_leech attribute_003_needs_chlorophyll_to_produce_food WMFalse
  livingbeings-cell-000-003 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_000_leech attribute_004_two_seed_leaves WMFalse
  livingbeings-cell-000-004 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_000_leech attribute_005_one_seed_leave WMFalse
  livingbeings-cell-000-005 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_000_leech attribute_006_can_move_around WMTrue
  livingbeings-cell-000-006 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_000_leech attribute_007_has_limbs WMFalse
  livingbeings-cell-000-007 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_000_leech attribute_008_suckles_its_offspring WMFalse
  livingbeings-cell-000-008 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_001_bream attribute_000_needs_water_to_live WMTrue
  livingbeings-cell-001-000 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_001_bream attribute_001_lives_in_water WMTrue
  livingbeings-cell-001-001 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_001_bream attribute_002_lives_on_land WMFalse
  livingbeings-cell-001-002 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_001_bream attribute_003_needs_chlorophyll_to_produce_food WMFalse
  livingbeings-cell-001-003 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_001_bream attribute_004_two_seed_leaves WMFalse
  livingbeings-cell-001-004 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_001_bream attribute_005_one_seed_leave WMFalse
  livingbeings-cell-001-005 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_001_bream attribute_006_can_move_around WMTrue
  livingbeings-cell-001-006 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_001_bream attribute_007_has_limbs WMTrue
  livingbeings-cell-001-007 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_001_bream attribute_008_suckles_its_offspring WMFalse
  livingbeings-cell-001-008 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_002_frog attribute_000_needs_water_to_live WMTrue
  livingbeings-cell-002-000 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_002_frog attribute_001_lives_in_water WMTrue
  livingbeings-cell-002-001 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_002_frog attribute_002_lives_on_land WMTrue
  livingbeings-cell-002-002 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_002_frog attribute_003_needs_chlorophyll_to_produce_food WMFalse
  livingbeings-cell-002-003 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_002_frog attribute_004_two_seed_leaves WMFalse
  livingbeings-cell-002-004 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_002_frog attribute_005_one_seed_leave WMFalse
  livingbeings-cell-002-005 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_002_frog attribute_006_can_move_around WMTrue
  livingbeings-cell-002-006 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_002_frog attribute_007_has_limbs WMTrue
  livingbeings-cell-002-007 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_002_frog attribute_008_suckles_its_offspring WMFalse
  livingbeings-cell-002-008 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_003_dog attribute_000_needs_water_to_live WMTrue
  livingbeings-cell-003-000 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_003_dog attribute_001_lives_in_water WMFalse
  livingbeings-cell-003-001 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_003_dog attribute_002_lives_on_land WMTrue
  livingbeings-cell-003-002 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_003_dog attribute_003_needs_chlorophyll_to_produce_food WMFalse
  livingbeings-cell-003-003 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_003_dog attribute_004_two_seed_leaves WMFalse
  livingbeings-cell-003-004 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_003_dog attribute_005_one_seed_leave WMFalse
  livingbeings-cell-003-005 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_003_dog attribute_006_can_move_around WMTrue
  livingbeings-cell-003-006 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_003_dog attribute_007_has_limbs WMTrue
  livingbeings-cell-003-007 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_003_dog attribute_008_suckles_its_offspring WMTrue
  livingbeings-cell-003-008 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_004_waterweed attribute_000_needs_water_to_live WMTrue
  livingbeings-cell-004-000 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_004_waterweed attribute_001_lives_in_water WMTrue
  livingbeings-cell-004-001 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_004_waterweed attribute_002_lives_on_land WMFalse
  livingbeings-cell-004-002 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_004_waterweed attribute_003_needs_chlorophyll_to_produce_food WMTrue
  livingbeings-cell-004-003 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_004_waterweed attribute_004_two_seed_leaves WMFalse
  livingbeings-cell-004-004 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_004_waterweed attribute_005_one_seed_leave WMTrue
  livingbeings-cell-004-005 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_004_waterweed attribute_006_can_move_around WMFalse
  livingbeings-cell-004-006 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_004_waterweed attribute_007_has_limbs WMFalse
  livingbeings-cell-004-007 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_004_waterweed attribute_008_suckles_its_offspring WMFalse
  livingbeings-cell-004-008 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_005_reed attribute_000_needs_water_to_live WMTrue
  livingbeings-cell-005-000 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_005_reed attribute_001_lives_in_water WMTrue
  livingbeings-cell-005-001 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_005_reed attribute_002_lives_on_land WMTrue
  livingbeings-cell-005-002 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_005_reed attribute_003_needs_chlorophyll_to_produce_food WMTrue
  livingbeings-cell-005-003 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_005_reed attribute_004_two_seed_leaves WMFalse
  livingbeings-cell-005-004 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_005_reed attribute_005_one_seed_leave WMTrue
  livingbeings-cell-005-005 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_005_reed attribute_006_can_move_around WMFalse
  livingbeings-cell-005-006 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_005_reed attribute_007_has_limbs WMFalse
  livingbeings-cell-005-007 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_005_reed attribute_008_suckles_its_offspring WMFalse
  livingbeings-cell-005-008 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_006_bean attribute_000_needs_water_to_live WMTrue
  livingbeings-cell-006-000 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_006_bean attribute_001_lives_in_water WMFalse
  livingbeings-cell-006-001 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_006_bean attribute_002_lives_on_land WMTrue
  livingbeings-cell-006-002 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_006_bean attribute_003_needs_chlorophyll_to_produce_food WMTrue
  livingbeings-cell-006-003 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_006_bean attribute_004_two_seed_leaves WMTrue
  livingbeings-cell-006-004 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_006_bean attribute_005_one_seed_leave WMFalse
  livingbeings-cell-006-005 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_006_bean attribute_006_can_move_around WMFalse
  livingbeings-cell-006-006 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_006_bean attribute_007_has_limbs WMFalse
  livingbeings-cell-006-007 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_006_bean attribute_008_suckles_its_offspring WMFalse
  livingbeings-cell-006-008 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_007_maize attribute_000_needs_water_to_live WMTrue
  livingbeings-cell-007-000 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_007_maize attribute_001_lives_in_water WMFalse
  livingbeings-cell-007-001 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_007_maize attribute_002_lives_on_land WMTrue
  livingbeings-cell-007-002 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_007_maize attribute_003_needs_chlorophyll_to_produce_food WMTrue
  livingbeings-cell-007-003 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_007_maize attribute_004_two_seed_leaves WMFalse
  livingbeings-cell-007-004 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_007_maize attribute_005_one_seed_leave WMTrue
  livingbeings-cell-007-005 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_007_maize attribute_006_can_move_around WMFalse
  livingbeings-cell-007-006 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_007_maize attribute_007_has_limbs WMFalse
  livingbeings-cell-007-007 fcatools-contexts-9306d256 livingbeings-published-matrix)
     (WMFCAObservation livingbeings object_007_maize attribute_008_suckles_its_offspring WMFalse
  livingbeings-cell-007-008 fcatools-contexts-9306d256 livingbeings-published-matrix))))

(= (wm-fca-livingbeings-oracle-intents)
   (
   (attribute_000_needs_water_to_live)
   (attribute_000_needs_water_to_live attribute_001_lives_in_water)
   (attribute_000_needs_water_to_live attribute_002_lives_on_land)
   (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food)
   (attribute_000_needs_water_to_live attribute_006_can_move_around)
   (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land)
   (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around)
   (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food)
   (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave)
   (attribute_000_needs_water_to_live attribute_006_can_move_around attribute_007_has_limbs)
   (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave)
   (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around attribute_007_has_limbs)
   (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves)
   (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave)
   (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs)
   (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave)
   (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs)
   (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring)
   (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring)))

(= (wm-fca-livingbeings-oracle-concepts)
   (
   (WMFCAConcept (object_000_leech object_001_bream object_002_frog object_003_dog object_004_waterweed object_005_reed object_006_bean object_007_maize) (attribute_000_needs_water_to_live))
   (WMFCAConcept (object_000_leech object_001_bream object_002_frog object_004_waterweed object_005_reed) (attribute_000_needs_water_to_live attribute_001_lives_in_water))
   (WMFCAConcept (object_002_frog object_003_dog object_005_reed object_006_bean object_007_maize) (attribute_000_needs_water_to_live attribute_002_lives_on_land))
   (WMFCAConcept (object_004_waterweed object_005_reed object_006_bean object_007_maize) (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food))
   (WMFCAConcept (object_000_leech object_001_bream object_002_frog object_003_dog) (attribute_000_needs_water_to_live attribute_006_can_move_around))
   (WMFCAConcept (object_002_frog object_005_reed) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land))
   (WMFCAConcept (object_000_leech object_001_bream object_002_frog) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around))
   (WMFCAConcept (object_005_reed object_006_bean object_007_maize) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food))
   (WMFCAConcept (object_004_waterweed object_005_reed object_007_maize) (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCAConcept (object_001_bream object_002_frog object_003_dog) (attribute_000_needs_water_to_live attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCAConcept (object_004_waterweed object_005_reed) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCAConcept (object_001_bream object_002_frog) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCAConcept (object_006_bean) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves))
   (WMFCAConcept (object_005_reed object_007_maize) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCAConcept (object_002_frog object_003_dog) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCAConcept (object_005_reed) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCAConcept (object_002_frog) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCAConcept (object_003_dog) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring))
   (WMFCAConcept () (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring))))

(= (wm-fca-livingbeings-oracle-basis)
   (
   (WMFCAImplication () (attribute_000_needs_water_to_live))
   (WMFCAImplication (attribute_000_needs_water_to_live attribute_004_two_seed_leaves) (attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food))
   (WMFCAImplication (attribute_000_needs_water_to_live attribute_005_one_seed_leave) (attribute_003_needs_chlorophyll_to_produce_food))
   (WMFCAImplication (attribute_000_needs_water_to_live attribute_007_has_limbs) (attribute_006_can_move_around))
   (WMFCAImplication (attribute_000_needs_water_to_live attribute_008_suckles_its_offspring) (attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCAImplication (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_003_needs_chlorophyll_to_produce_food) (attribute_005_one_seed_leave))
   (WMFCAImplication (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around) (attribute_007_has_limbs))
   (WMFCAImplication (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food attribute_006_can_move_around) (attribute_001_lives_in_water attribute_002_lives_on_land attribute_004_two_seed_leaves attribute_005_one_seed_leave attribute_007_has_limbs attribute_008_suckles_its_offspring))
   (WMFCAImplication (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave) (attribute_001_lives_in_water attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring))
   (WMFCAImplication (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring) (attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave))))

; Cover direction follows intent inclusion: general intent -> specific intent.
(= (wm-fca-livingbeings-oracle-covers)
   (
   (WMFCACover (attribute_000_needs_water_to_live) (attribute_000_needs_water_to_live attribute_001_lives_in_water))
   (WMFCACover (attribute_000_needs_water_to_live) (attribute_000_needs_water_to_live attribute_002_lives_on_land))
   (WMFCACover (attribute_000_needs_water_to_live) (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food))
   (WMFCACover (attribute_000_needs_water_to_live) (attribute_000_needs_water_to_live attribute_006_can_move_around))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCACover (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food))
   (WMFCACover (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food) (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCACover (attribute_000_needs_water_to_live attribute_006_can_move_around) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around))
   (WMFCACover (attribute_000_needs_water_to_live attribute_006_can_move_around) (attribute_000_needs_water_to_live attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCACover (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCACover (attribute_000_needs_water_to_live attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCACover (attribute_000_needs_water_to_live attribute_006_can_move_around attribute_007_has_limbs) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCACover (attribute_000_needs_water_to_live attribute_006_can_move_around attribute_007_has_limbs) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_006_can_move_around attribute_007_has_limbs) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs) (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_005_one_seed_leave) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring))
   (WMFCACover (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring))
   (WMFCACover (attribute_000_needs_water_to_live attribute_002_lives_on_land attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring) (attribute_000_needs_water_to_live attribute_001_lives_in_water attribute_002_lives_on_land attribute_003_needs_chlorophyll_to_produce_food attribute_004_two_seed_leaves attribute_005_one_seed_leave attribute_006_can_move_around attribute_007_has_limbs attribute_008_suckles_its_offspring))))
