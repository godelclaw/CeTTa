; Generated from a pinned public Formal Concept Analysis context.
; Source: https://github.com/fcatools/contexts/blob/9306d256c8a212ffa0c60a52f883a516d8b87b58/contexts/animals_en.cxt
; SHA-256: 8a91853b8189c2e3cf6f9257d05967384c65db8deb55aacb8cff1ee4516828cd
;
; The context is complete: all 35 x 11 cells are
; explicit observations.  Matrix zeroes are WMFalse, never WMMissing.  A single
; dependence group records that the cells belong to one published matrix.

!(import! &self lib_wm_fca)

(= (wm-fca-animals-objects)
   (object_000_alligator object_001_rattler object_002_pig object_003_eagle object_004_dog object_005_cat object_006_dove object_007_lion object_008_hippo object_009_elephant object_010_thrasher object_011_bull_snake object_012_mouse object_013_skunk object_014_lizard object_015_zebra object_016_tiger object_017_bear object_018_ibex object_019_antelope object_020_moose object_021_horse object_022_cow object_023_shark object_024_trout object_025_whale object_026_dolphin object_027_stingray object_028_possum object_029_barracuda object_030_parakeet object_031_sheep object_032_goat object_033_chicken object_034_tarantula))

(= (wm-fca-animals-attributes)
   (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))

(= (wm-fca-animals-state)
   (WMFCAState
     (object_000_alligator object_001_rattler object_002_pig object_003_eagle object_004_dog object_005_cat object_006_dove object_007_lion object_008_hippo object_009_elephant object_010_thrasher object_011_bull_snake object_012_mouse object_013_skunk object_014_lizard object_015_zebra object_016_tiger object_017_bear object_018_ibex object_019_antelope object_020_moose object_021_horse object_022_cow object_023_shark object_024_trout object_025_whale object_026_dolphin object_027_stingray object_028_possum object_029_barracuda object_030_parakeet object_031_sheep object_032_goat object_033_chicken object_034_tarantula)
     (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales)
     (
     (WMFCAObservation animals object_000_alligator attribute_000_eggs WMTrue
  animals-cell-000-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_001_nocturnal WMFalse
  animals-cell-000-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_002_man_eater WMTrue
  animals-cell-000-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_003_pet WMFalse
  animals-cell-000-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_004_livestock WMFalse
  animals-cell-000-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_005_lives_in_water WMTrue
  animals-cell-000-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_006_airbreather WMTrue
  animals-cell-000-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_007_warmblooded WMFalse
  animals-cell-000-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_008_four_legged WMTrue
  animals-cell-000-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_009_fur WMFalse
  animals-cell-000-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_000_alligator attribute_010_scales WMTrue
  animals-cell-000-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_000_eggs WMTrue
  animals-cell-001-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_001_nocturnal WMTrue
  animals-cell-001-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_002_man_eater WMFalse
  animals-cell-001-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_003_pet WMFalse
  animals-cell-001-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_004_livestock WMFalse
  animals-cell-001-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_005_lives_in_water WMFalse
  animals-cell-001-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_006_airbreather WMTrue
  animals-cell-001-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_007_warmblooded WMFalse
  animals-cell-001-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_008_four_legged WMFalse
  animals-cell-001-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_009_fur WMFalse
  animals-cell-001-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_001_rattler attribute_010_scales WMTrue
  animals-cell-001-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_000_eggs WMFalse
  animals-cell-002-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_001_nocturnal WMFalse
  animals-cell-002-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_002_man_eater WMFalse
  animals-cell-002-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_003_pet WMFalse
  animals-cell-002-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_004_livestock WMFalse
  animals-cell-002-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_005_lives_in_water WMFalse
  animals-cell-002-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_006_airbreather WMTrue
  animals-cell-002-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_007_warmblooded WMTrue
  animals-cell-002-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_008_four_legged WMTrue
  animals-cell-002-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_009_fur WMTrue
  animals-cell-002-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_002_pig attribute_010_scales WMFalse
  animals-cell-002-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_000_eggs WMTrue
  animals-cell-003-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_001_nocturnal WMFalse
  animals-cell-003-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_002_man_eater WMFalse
  animals-cell-003-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_003_pet WMFalse
  animals-cell-003-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_004_livestock WMFalse
  animals-cell-003-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_005_lives_in_water WMFalse
  animals-cell-003-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_006_airbreather WMTrue
  animals-cell-003-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_007_warmblooded WMTrue
  animals-cell-003-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_008_four_legged WMFalse
  animals-cell-003-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_009_fur WMFalse
  animals-cell-003-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_003_eagle attribute_010_scales WMFalse
  animals-cell-003-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_000_eggs WMFalse
  animals-cell-004-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_001_nocturnal WMFalse
  animals-cell-004-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_002_man_eater WMFalse
  animals-cell-004-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_003_pet WMTrue
  animals-cell-004-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_004_livestock WMFalse
  animals-cell-004-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_005_lives_in_water WMFalse
  animals-cell-004-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_006_airbreather WMTrue
  animals-cell-004-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_007_warmblooded WMTrue
  animals-cell-004-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_008_four_legged WMTrue
  animals-cell-004-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_009_fur WMTrue
  animals-cell-004-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_004_dog attribute_010_scales WMFalse
  animals-cell-004-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_000_eggs WMFalse
  animals-cell-005-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_001_nocturnal WMTrue
  animals-cell-005-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_002_man_eater WMFalse
  animals-cell-005-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_003_pet WMTrue
  animals-cell-005-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_004_livestock WMFalse
  animals-cell-005-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_005_lives_in_water WMFalse
  animals-cell-005-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_006_airbreather WMTrue
  animals-cell-005-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_007_warmblooded WMTrue
  animals-cell-005-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_008_four_legged WMTrue
  animals-cell-005-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_009_fur WMTrue
  animals-cell-005-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_005_cat attribute_010_scales WMFalse
  animals-cell-005-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_000_eggs WMTrue
  animals-cell-006-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_001_nocturnal WMFalse
  animals-cell-006-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_002_man_eater WMFalse
  animals-cell-006-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_003_pet WMFalse
  animals-cell-006-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_004_livestock WMFalse
  animals-cell-006-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_005_lives_in_water WMFalse
  animals-cell-006-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_006_airbreather WMTrue
  animals-cell-006-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_007_warmblooded WMTrue
  animals-cell-006-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_008_four_legged WMFalse
  animals-cell-006-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_009_fur WMFalse
  animals-cell-006-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_006_dove attribute_010_scales WMFalse
  animals-cell-006-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_000_eggs WMFalse
  animals-cell-007-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_001_nocturnal WMFalse
  animals-cell-007-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_002_man_eater WMTrue
  animals-cell-007-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_003_pet WMFalse
  animals-cell-007-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_004_livestock WMFalse
  animals-cell-007-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_005_lives_in_water WMFalse
  animals-cell-007-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_006_airbreather WMTrue
  animals-cell-007-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_007_warmblooded WMTrue
  animals-cell-007-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_008_four_legged WMTrue
  animals-cell-007-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_009_fur WMTrue
  animals-cell-007-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_007_lion attribute_010_scales WMFalse
  animals-cell-007-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_000_eggs WMFalse
  animals-cell-008-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_001_nocturnal WMFalse
  animals-cell-008-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_002_man_eater WMFalse
  animals-cell-008-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_003_pet WMFalse
  animals-cell-008-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_004_livestock WMFalse
  animals-cell-008-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_005_lives_in_water WMFalse
  animals-cell-008-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_006_airbreather WMTrue
  animals-cell-008-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_007_warmblooded WMTrue
  animals-cell-008-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_008_four_legged WMTrue
  animals-cell-008-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_009_fur WMFalse
  animals-cell-008-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_008_hippo attribute_010_scales WMFalse
  animals-cell-008-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_000_eggs WMFalse
  animals-cell-009-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_001_nocturnal WMFalse
  animals-cell-009-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_002_man_eater WMFalse
  animals-cell-009-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_003_pet WMFalse
  animals-cell-009-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_004_livestock WMFalse
  animals-cell-009-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_005_lives_in_water WMFalse
  animals-cell-009-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_006_airbreather WMTrue
  animals-cell-009-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_007_warmblooded WMTrue
  animals-cell-009-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_008_four_legged WMTrue
  animals-cell-009-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_009_fur WMFalse
  animals-cell-009-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_009_elephant attribute_010_scales WMFalse
  animals-cell-009-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_000_eggs WMTrue
  animals-cell-010-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_001_nocturnal WMFalse
  animals-cell-010-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_002_man_eater WMFalse
  animals-cell-010-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_003_pet WMFalse
  animals-cell-010-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_004_livestock WMFalse
  animals-cell-010-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_005_lives_in_water WMFalse
  animals-cell-010-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_006_airbreather WMTrue
  animals-cell-010-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_007_warmblooded WMTrue
  animals-cell-010-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_008_four_legged WMFalse
  animals-cell-010-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_009_fur WMFalse
  animals-cell-010-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_010_thrasher attribute_010_scales WMFalse
  animals-cell-010-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_000_eggs WMTrue
  animals-cell-011-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_001_nocturnal WMFalse
  animals-cell-011-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_002_man_eater WMFalse
  animals-cell-011-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_003_pet WMFalse
  animals-cell-011-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_004_livestock WMFalse
  animals-cell-011-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_005_lives_in_water WMFalse
  animals-cell-011-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_006_airbreather WMTrue
  animals-cell-011-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_007_warmblooded WMFalse
  animals-cell-011-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_008_four_legged WMFalse
  animals-cell-011-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_009_fur WMFalse
  animals-cell-011-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_011_bull_snake attribute_010_scales WMTrue
  animals-cell-011-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_000_eggs WMFalse
  animals-cell-012-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_001_nocturnal WMFalse
  animals-cell-012-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_002_man_eater WMFalse
  animals-cell-012-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_003_pet WMFalse
  animals-cell-012-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_004_livestock WMFalse
  animals-cell-012-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_005_lives_in_water WMFalse
  animals-cell-012-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_006_airbreather WMTrue
  animals-cell-012-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_007_warmblooded WMTrue
  animals-cell-012-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_008_four_legged WMTrue
  animals-cell-012-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_009_fur WMTrue
  animals-cell-012-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_012_mouse attribute_010_scales WMFalse
  animals-cell-012-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_000_eggs WMFalse
  animals-cell-013-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_001_nocturnal WMTrue
  animals-cell-013-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_002_man_eater WMFalse
  animals-cell-013-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_003_pet WMFalse
  animals-cell-013-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_004_livestock WMFalse
  animals-cell-013-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_005_lives_in_water WMFalse
  animals-cell-013-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_006_airbreather WMTrue
  animals-cell-013-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_007_warmblooded WMTrue
  animals-cell-013-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_008_four_legged WMTrue
  animals-cell-013-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_009_fur WMTrue
  animals-cell-013-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_013_skunk attribute_010_scales WMFalse
  animals-cell-013-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_000_eggs WMTrue
  animals-cell-014-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_001_nocturnal WMFalse
  animals-cell-014-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_002_man_eater WMFalse
  animals-cell-014-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_003_pet WMFalse
  animals-cell-014-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_004_livestock WMFalse
  animals-cell-014-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_005_lives_in_water WMFalse
  animals-cell-014-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_006_airbreather WMTrue
  animals-cell-014-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_007_warmblooded WMFalse
  animals-cell-014-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_008_four_legged WMTrue
  animals-cell-014-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_009_fur WMFalse
  animals-cell-014-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_014_lizard attribute_010_scales WMTrue
  animals-cell-014-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_000_eggs WMFalse
  animals-cell-015-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_001_nocturnal WMFalse
  animals-cell-015-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_002_man_eater WMFalse
  animals-cell-015-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_003_pet WMFalse
  animals-cell-015-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_004_livestock WMFalse
  animals-cell-015-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_005_lives_in_water WMFalse
  animals-cell-015-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_006_airbreather WMTrue
  animals-cell-015-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_007_warmblooded WMTrue
  animals-cell-015-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_008_four_legged WMTrue
  animals-cell-015-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_009_fur WMTrue
  animals-cell-015-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_015_zebra attribute_010_scales WMFalse
  animals-cell-015-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_000_eggs WMFalse
  animals-cell-016-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_001_nocturnal WMFalse
  animals-cell-016-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_002_man_eater WMTrue
  animals-cell-016-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_003_pet WMFalse
  animals-cell-016-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_004_livestock WMFalse
  animals-cell-016-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_005_lives_in_water WMFalse
  animals-cell-016-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_006_airbreather WMTrue
  animals-cell-016-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_007_warmblooded WMTrue
  animals-cell-016-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_008_four_legged WMTrue
  animals-cell-016-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_009_fur WMTrue
  animals-cell-016-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_016_tiger attribute_010_scales WMFalse
  animals-cell-016-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_000_eggs WMFalse
  animals-cell-017-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_001_nocturnal WMFalse
  animals-cell-017-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_002_man_eater WMTrue
  animals-cell-017-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_003_pet WMFalse
  animals-cell-017-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_004_livestock WMFalse
  animals-cell-017-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_005_lives_in_water WMFalse
  animals-cell-017-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_006_airbreather WMTrue
  animals-cell-017-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_007_warmblooded WMTrue
  animals-cell-017-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_008_four_legged WMTrue
  animals-cell-017-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_009_fur WMTrue
  animals-cell-017-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_017_bear attribute_010_scales WMFalse
  animals-cell-017-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_000_eggs WMFalse
  animals-cell-018-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_001_nocturnal WMFalse
  animals-cell-018-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_002_man_eater WMFalse
  animals-cell-018-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_003_pet WMFalse
  animals-cell-018-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_004_livestock WMFalse
  animals-cell-018-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_005_lives_in_water WMFalse
  animals-cell-018-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_006_airbreather WMTrue
  animals-cell-018-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_007_warmblooded WMTrue
  animals-cell-018-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_008_four_legged WMTrue
  animals-cell-018-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_009_fur WMTrue
  animals-cell-018-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_018_ibex attribute_010_scales WMFalse
  animals-cell-018-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_000_eggs WMFalse
  animals-cell-019-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_001_nocturnal WMFalse
  animals-cell-019-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_002_man_eater WMFalse
  animals-cell-019-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_003_pet WMFalse
  animals-cell-019-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_004_livestock WMFalse
  animals-cell-019-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_005_lives_in_water WMFalse
  animals-cell-019-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_006_airbreather WMTrue
  animals-cell-019-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_007_warmblooded WMTrue
  animals-cell-019-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_008_four_legged WMTrue
  animals-cell-019-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_009_fur WMTrue
  animals-cell-019-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_019_antelope attribute_010_scales WMFalse
  animals-cell-019-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_000_eggs WMFalse
  animals-cell-020-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_001_nocturnal WMFalse
  animals-cell-020-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_002_man_eater WMFalse
  animals-cell-020-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_003_pet WMFalse
  animals-cell-020-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_004_livestock WMFalse
  animals-cell-020-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_005_lives_in_water WMFalse
  animals-cell-020-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_006_airbreather WMTrue
  animals-cell-020-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_007_warmblooded WMTrue
  animals-cell-020-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_008_four_legged WMTrue
  animals-cell-020-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_009_fur WMTrue
  animals-cell-020-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_020_moose attribute_010_scales WMFalse
  animals-cell-020-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_000_eggs WMFalse
  animals-cell-021-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_001_nocturnal WMFalse
  animals-cell-021-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_002_man_eater WMFalse
  animals-cell-021-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_003_pet WMFalse
  animals-cell-021-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_004_livestock WMTrue
  animals-cell-021-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_005_lives_in_water WMFalse
  animals-cell-021-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_006_airbreather WMTrue
  animals-cell-021-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_007_warmblooded WMTrue
  animals-cell-021-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_008_four_legged WMTrue
  animals-cell-021-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_009_fur WMTrue
  animals-cell-021-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_021_horse attribute_010_scales WMFalse
  animals-cell-021-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_000_eggs WMFalse
  animals-cell-022-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_001_nocturnal WMFalse
  animals-cell-022-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_002_man_eater WMFalse
  animals-cell-022-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_003_pet WMFalse
  animals-cell-022-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_004_livestock WMTrue
  animals-cell-022-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_005_lives_in_water WMFalse
  animals-cell-022-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_006_airbreather WMTrue
  animals-cell-022-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_007_warmblooded WMTrue
  animals-cell-022-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_008_four_legged WMTrue
  animals-cell-022-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_009_fur WMTrue
  animals-cell-022-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_022_cow attribute_010_scales WMFalse
  animals-cell-022-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_000_eggs WMFalse
  animals-cell-023-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_001_nocturnal WMFalse
  animals-cell-023-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_002_man_eater WMTrue
  animals-cell-023-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_003_pet WMFalse
  animals-cell-023-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_004_livestock WMFalse
  animals-cell-023-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_005_lives_in_water WMTrue
  animals-cell-023-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_006_airbreather WMFalse
  animals-cell-023-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_007_warmblooded WMFalse
  animals-cell-023-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_008_four_legged WMFalse
  animals-cell-023-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_009_fur WMFalse
  animals-cell-023-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_023_shark attribute_010_scales WMTrue
  animals-cell-023-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_000_eggs WMTrue
  animals-cell-024-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_001_nocturnal WMFalse
  animals-cell-024-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_002_man_eater WMFalse
  animals-cell-024-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_003_pet WMFalse
  animals-cell-024-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_004_livestock WMFalse
  animals-cell-024-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_005_lives_in_water WMTrue
  animals-cell-024-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_006_airbreather WMFalse
  animals-cell-024-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_007_warmblooded WMFalse
  animals-cell-024-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_008_four_legged WMFalse
  animals-cell-024-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_009_fur WMFalse
  animals-cell-024-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_024_trout attribute_010_scales WMTrue
  animals-cell-024-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_000_eggs WMFalse
  animals-cell-025-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_001_nocturnal WMFalse
  animals-cell-025-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_002_man_eater WMFalse
  animals-cell-025-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_003_pet WMFalse
  animals-cell-025-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_004_livestock WMFalse
  animals-cell-025-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_005_lives_in_water WMTrue
  animals-cell-025-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_006_airbreather WMTrue
  animals-cell-025-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_007_warmblooded WMTrue
  animals-cell-025-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_008_four_legged WMFalse
  animals-cell-025-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_009_fur WMFalse
  animals-cell-025-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_025_whale attribute_010_scales WMFalse
  animals-cell-025-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_000_eggs WMFalse
  animals-cell-026-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_001_nocturnal WMFalse
  animals-cell-026-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_002_man_eater WMFalse
  animals-cell-026-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_003_pet WMFalse
  animals-cell-026-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_004_livestock WMFalse
  animals-cell-026-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_005_lives_in_water WMTrue
  animals-cell-026-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_006_airbreather WMTrue
  animals-cell-026-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_007_warmblooded WMTrue
  animals-cell-026-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_008_four_legged WMFalse
  animals-cell-026-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_009_fur WMFalse
  animals-cell-026-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_026_dolphin attribute_010_scales WMFalse
  animals-cell-026-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_000_eggs WMTrue
  animals-cell-027-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_001_nocturnal WMFalse
  animals-cell-027-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_002_man_eater WMFalse
  animals-cell-027-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_003_pet WMFalse
  animals-cell-027-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_004_livestock WMFalse
  animals-cell-027-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_005_lives_in_water WMTrue
  animals-cell-027-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_006_airbreather WMFalse
  animals-cell-027-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_007_warmblooded WMFalse
  animals-cell-027-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_008_four_legged WMFalse
  animals-cell-027-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_009_fur WMFalse
  animals-cell-027-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_027_stingray attribute_010_scales WMTrue
  animals-cell-027-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_000_eggs WMFalse
  animals-cell-028-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_001_nocturnal WMTrue
  animals-cell-028-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_002_man_eater WMFalse
  animals-cell-028-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_003_pet WMFalse
  animals-cell-028-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_004_livestock WMFalse
  animals-cell-028-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_005_lives_in_water WMFalse
  animals-cell-028-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_006_airbreather WMTrue
  animals-cell-028-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_007_warmblooded WMTrue
  animals-cell-028-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_008_four_legged WMTrue
  animals-cell-028-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_009_fur WMTrue
  animals-cell-028-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_028_possum attribute_010_scales WMFalse
  animals-cell-028-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_000_eggs WMFalse
  animals-cell-029-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_001_nocturnal WMFalse
  animals-cell-029-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_002_man_eater WMFalse
  animals-cell-029-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_003_pet WMFalse
  animals-cell-029-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_004_livestock WMFalse
  animals-cell-029-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_005_lives_in_water WMTrue
  animals-cell-029-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_006_airbreather WMFalse
  animals-cell-029-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_007_warmblooded WMFalse
  animals-cell-029-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_008_four_legged WMFalse
  animals-cell-029-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_009_fur WMFalse
  animals-cell-029-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_029_barracuda attribute_010_scales WMTrue
  animals-cell-029-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_000_eggs WMTrue
  animals-cell-030-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_001_nocturnal WMFalse
  animals-cell-030-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_002_man_eater WMFalse
  animals-cell-030-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_003_pet WMTrue
  animals-cell-030-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_004_livestock WMFalse
  animals-cell-030-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_005_lives_in_water WMFalse
  animals-cell-030-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_006_airbreather WMTrue
  animals-cell-030-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_007_warmblooded WMTrue
  animals-cell-030-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_008_four_legged WMFalse
  animals-cell-030-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_009_fur WMFalse
  animals-cell-030-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_030_parakeet attribute_010_scales WMFalse
  animals-cell-030-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_000_eggs WMFalse
  animals-cell-031-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_001_nocturnal WMFalse
  animals-cell-031-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_002_man_eater WMFalse
  animals-cell-031-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_003_pet WMFalse
  animals-cell-031-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_004_livestock WMTrue
  animals-cell-031-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_005_lives_in_water WMFalse
  animals-cell-031-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_006_airbreather WMTrue
  animals-cell-031-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_007_warmblooded WMTrue
  animals-cell-031-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_008_four_legged WMTrue
  animals-cell-031-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_009_fur WMTrue
  animals-cell-031-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_031_sheep attribute_010_scales WMFalse
  animals-cell-031-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_000_eggs WMFalse
  animals-cell-032-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_001_nocturnal WMFalse
  animals-cell-032-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_002_man_eater WMFalse
  animals-cell-032-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_003_pet WMFalse
  animals-cell-032-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_004_livestock WMTrue
  animals-cell-032-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_005_lives_in_water WMFalse
  animals-cell-032-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_006_airbreather WMTrue
  animals-cell-032-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_007_warmblooded WMTrue
  animals-cell-032-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_008_four_legged WMTrue
  animals-cell-032-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_009_fur WMTrue
  animals-cell-032-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_032_goat attribute_010_scales WMFalse
  animals-cell-032-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_000_eggs WMTrue
  animals-cell-033-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_001_nocturnal WMFalse
  animals-cell-033-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_002_man_eater WMFalse
  animals-cell-033-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_003_pet WMFalse
  animals-cell-033-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_004_livestock WMTrue
  animals-cell-033-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_005_lives_in_water WMFalse
  animals-cell-033-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_006_airbreather WMTrue
  animals-cell-033-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_007_warmblooded WMTrue
  animals-cell-033-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_008_four_legged WMFalse
  animals-cell-033-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_009_fur WMFalse
  animals-cell-033-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_033_chicken attribute_010_scales WMFalse
  animals-cell-033-010 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_000_eggs WMTrue
  animals-cell-034-000 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_001_nocturnal WMTrue
  animals-cell-034-001 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_002_man_eater WMFalse
  animals-cell-034-002 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_003_pet WMFalse
  animals-cell-034-003 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_004_livestock WMFalse
  animals-cell-034-004 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_005_lives_in_water WMFalse
  animals-cell-034-005 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_006_airbreather WMTrue
  animals-cell-034-006 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_007_warmblooded WMFalse
  animals-cell-034-007 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_008_four_legged WMFalse
  animals-cell-034-008 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_009_fur WMFalse
  animals-cell-034-009 fcatools-contexts-9306d256 animals-published-matrix)
     (WMFCAObservation animals object_034_tarantula attribute_010_scales WMFalse
  animals-cell-034-010 fcatools-contexts-9306d256 animals-published-matrix))))

(= (wm-fca-animals-oracle-intents)
   (
   ()
   (attribute_000_eggs)
   (attribute_002_man_eater)
   (attribute_005_lives_in_water)
   (attribute_006_airbreather)
   (attribute_010_scales)
   (attribute_000_eggs attribute_006_airbreather)
   (attribute_000_eggs attribute_010_scales)
   (attribute_001_nocturnal attribute_006_airbreather)
   (attribute_005_lives_in_water attribute_006_airbreather)
   (attribute_005_lives_in_water attribute_010_scales)
   (attribute_006_airbreather attribute_007_warmblooded)
   (attribute_006_airbreather attribute_008_four_legged)
   (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather)
   (attribute_000_eggs attribute_005_lives_in_water attribute_010_scales)
   (attribute_000_eggs attribute_006_airbreather attribute_007_warmblooded)
   (attribute_000_eggs attribute_006_airbreather attribute_010_scales)
   (attribute_002_man_eater attribute_005_lives_in_water attribute_010_scales)
   (attribute_002_man_eater attribute_006_airbreather attribute_008_four_legged)
   (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded)
   (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded)
   (attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded)
   (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged)
   (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather attribute_010_scales)
   (attribute_000_eggs attribute_003_pet attribute_006_airbreather attribute_007_warmblooded)
   (attribute_000_eggs attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded)
   (attribute_000_eggs attribute_006_airbreather attribute_008_four_legged attribute_010_scales)
   (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur)
   (attribute_001_nocturnal attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur)
   (attribute_002_man_eater attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur)
   (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur)
   (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur)
   (attribute_000_eggs attribute_002_man_eater attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged attribute_010_scales)
   (attribute_001_nocturnal attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur)
   (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales)))

(= (wm-fca-animals-oracle-concepts)
   (
   (WMFCAConcept (object_000_alligator object_001_rattler object_002_pig object_003_eagle object_004_dog object_005_cat object_006_dove object_007_lion object_008_hippo object_009_elephant object_010_thrasher object_011_bull_snake object_012_mouse object_013_skunk object_014_lizard object_015_zebra object_016_tiger object_017_bear object_018_ibex object_019_antelope object_020_moose object_021_horse object_022_cow object_023_shark object_024_trout object_025_whale object_026_dolphin object_027_stingray object_028_possum object_029_barracuda object_030_parakeet object_031_sheep object_032_goat object_033_chicken object_034_tarantula) ())
   (WMFCAConcept (object_000_alligator object_001_rattler object_003_eagle object_006_dove object_010_thrasher object_011_bull_snake object_014_lizard object_024_trout object_027_stingray object_030_parakeet object_033_chicken object_034_tarantula) (attribute_000_eggs))
   (WMFCAConcept (object_000_alligator object_007_lion object_016_tiger object_017_bear object_023_shark) (attribute_002_man_eater))
   (WMFCAConcept (object_000_alligator object_023_shark object_024_trout object_025_whale object_026_dolphin object_027_stingray object_029_barracuda) (attribute_005_lives_in_water))
   (WMFCAConcept (object_000_alligator object_001_rattler object_002_pig object_003_eagle object_004_dog object_005_cat object_006_dove object_007_lion object_008_hippo object_009_elephant object_010_thrasher object_011_bull_snake object_012_mouse object_013_skunk object_014_lizard object_015_zebra object_016_tiger object_017_bear object_018_ibex object_019_antelope object_020_moose object_021_horse object_022_cow object_025_whale object_026_dolphin object_028_possum object_030_parakeet object_031_sheep object_032_goat object_033_chicken object_034_tarantula) (attribute_006_airbreather))
   (WMFCAConcept (object_000_alligator object_001_rattler object_011_bull_snake object_014_lizard object_023_shark object_024_trout object_027_stingray object_029_barracuda) (attribute_010_scales))
   (WMFCAConcept (object_000_alligator object_001_rattler object_003_eagle object_006_dove object_010_thrasher object_011_bull_snake object_014_lizard object_030_parakeet object_033_chicken object_034_tarantula) (attribute_000_eggs attribute_006_airbreather))
   (WMFCAConcept (object_000_alligator object_001_rattler object_011_bull_snake object_014_lizard object_024_trout object_027_stingray) (attribute_000_eggs attribute_010_scales))
   (WMFCAConcept (object_001_rattler object_005_cat object_013_skunk object_028_possum object_034_tarantula) (attribute_001_nocturnal attribute_006_airbreather))
   (WMFCAConcept (object_000_alligator object_025_whale object_026_dolphin) (attribute_005_lives_in_water attribute_006_airbreather))
   (WMFCAConcept (object_000_alligator object_023_shark object_024_trout object_027_stingray object_029_barracuda) (attribute_005_lives_in_water attribute_010_scales))
   (WMFCAConcept (object_002_pig object_003_eagle object_004_dog object_005_cat object_006_dove object_007_lion object_008_hippo object_009_elephant object_010_thrasher object_012_mouse object_013_skunk object_015_zebra object_016_tiger object_017_bear object_018_ibex object_019_antelope object_020_moose object_021_horse object_022_cow object_025_whale object_026_dolphin object_028_possum object_030_parakeet object_031_sheep object_032_goat object_033_chicken) (attribute_006_airbreather attribute_007_warmblooded))
   (WMFCAConcept (object_000_alligator object_002_pig object_004_dog object_005_cat object_007_lion object_008_hippo object_009_elephant object_012_mouse object_013_skunk object_014_lizard object_015_zebra object_016_tiger object_017_bear object_018_ibex object_019_antelope object_020_moose object_021_horse object_022_cow object_028_possum object_031_sheep object_032_goat) (attribute_006_airbreather attribute_008_four_legged))
   (WMFCAConcept (object_001_rattler object_034_tarantula) (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather))
   (WMFCAConcept (object_000_alligator object_024_trout object_027_stingray) (attribute_000_eggs attribute_005_lives_in_water attribute_010_scales))
   (WMFCAConcept (object_003_eagle object_006_dove object_010_thrasher object_030_parakeet object_033_chicken) (attribute_000_eggs attribute_006_airbreather attribute_007_warmblooded))
   (WMFCAConcept (object_000_alligator object_001_rattler object_011_bull_snake object_014_lizard) (attribute_000_eggs attribute_006_airbreather attribute_010_scales))
   (WMFCAConcept (object_000_alligator object_023_shark) (attribute_002_man_eater attribute_005_lives_in_water attribute_010_scales))
   (WMFCAConcept (object_000_alligator object_007_lion object_016_tiger object_017_bear) (attribute_002_man_eater attribute_006_airbreather attribute_008_four_legged))
   (WMFCAConcept (object_004_dog object_005_cat object_030_parakeet) (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded))
   (WMFCAConcept (object_021_horse object_022_cow object_031_sheep object_032_goat object_033_chicken) (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded))
   (WMFCAConcept (object_025_whale object_026_dolphin) (attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded))
   (WMFCAConcept (object_002_pig object_004_dog object_005_cat object_007_lion object_008_hippo object_009_elephant object_012_mouse object_013_skunk object_015_zebra object_016_tiger object_017_bear object_018_ibex object_019_antelope object_020_moose object_021_horse object_022_cow object_028_possum object_031_sheep object_032_goat) (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged))
   (WMFCAConcept (object_001_rattler) (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather attribute_010_scales))
   (WMFCAConcept (object_030_parakeet) (attribute_000_eggs attribute_003_pet attribute_006_airbreather attribute_007_warmblooded))
   (WMFCAConcept (object_033_chicken) (attribute_000_eggs attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded))
   (WMFCAConcept (object_000_alligator object_014_lizard) (attribute_000_eggs attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCAConcept (object_002_pig object_004_dog object_005_cat object_007_lion object_012_mouse object_013_skunk object_015_zebra object_016_tiger object_017_bear object_018_ibex object_019_antelope object_020_moose object_021_horse object_022_cow object_028_possum object_031_sheep object_032_goat) (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCAConcept (object_005_cat object_013_skunk object_028_possum) (attribute_001_nocturnal attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCAConcept (object_007_lion object_016_tiger object_017_bear) (attribute_002_man_eater attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCAConcept (object_004_dog object_005_cat) (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCAConcept (object_021_horse object_022_cow object_031_sheep object_032_goat) (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCAConcept (object_000_alligator) (attribute_000_eggs attribute_002_man_eater attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCAConcept (object_005_cat) (attribute_001_nocturnal attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCAConcept () (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))))

(= (wm-fca-animals-oracle-basis)
   (
   (WMFCAImplication (attribute_001_nocturnal) (attribute_006_airbreather))
   (WMFCAImplication (attribute_003_pet) (attribute_006_airbreather attribute_007_warmblooded))
   (WMFCAImplication (attribute_004_livestock) (attribute_006_airbreather attribute_007_warmblooded))
   (WMFCAImplication (attribute_007_warmblooded) (attribute_006_airbreather))
   (WMFCAImplication (attribute_008_four_legged) (attribute_006_airbreather))
   (WMFCAImplication (attribute_009_fur) (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged))
   (WMFCAImplication (attribute_000_eggs attribute_002_man_eater) (attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCAImplication (attribute_000_eggs attribute_005_lives_in_water) (attribute_010_scales))
   (WMFCAImplication (attribute_002_man_eater attribute_005_lives_in_water) (attribute_010_scales))
   (WMFCAImplication (attribute_002_man_eater attribute_006_airbreather) (attribute_008_four_legged))
   (WMFCAImplication (attribute_002_man_eater attribute_010_scales) (attribute_005_lives_in_water))
   (WMFCAImplication (attribute_006_airbreather attribute_010_scales) (attribute_000_eggs))
   (WMFCAImplication (attribute_000_eggs attribute_006_airbreather attribute_008_four_legged) (attribute_010_scales))
   (WMFCAImplication (attribute_001_nocturnal attribute_005_lives_in_water attribute_006_airbreather) (attribute_000_eggs attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCAImplication (attribute_001_nocturnal attribute_006_airbreather attribute_007_warmblooded) (attribute_008_four_legged attribute_009_fur))
   (WMFCAImplication (attribute_001_nocturnal attribute_006_airbreather attribute_008_four_legged) (attribute_007_warmblooded attribute_009_fur))
   (WMFCAImplication (attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged) (attribute_000_eggs attribute_002_man_eater attribute_010_scales))
   (WMFCAImplication (attribute_000_eggs attribute_005_lives_in_water attribute_006_airbreather attribute_010_scales) (attribute_002_man_eater attribute_008_four_legged))
   (WMFCAImplication (attribute_000_eggs attribute_006_airbreather attribute_007_warmblooded attribute_010_scales) (attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_008_four_legged attribute_009_fur))
   (WMFCAImplication (attribute_002_man_eater attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged) (attribute_009_fur))
   (WMFCAImplication (attribute_003_pet attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_005_lives_in_water attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCAImplication (attribute_003_pet attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_004_livestock attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCAImplication (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged) (attribute_009_fur))
   (WMFCAImplication (attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCAImplication (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged) (attribute_009_fur))
   (WMFCAImplication (attribute_001_nocturnal attribute_002_man_eater attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_000_eggs attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_010_scales))
   (WMFCAImplication (attribute_001_nocturnal attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_000_eggs attribute_002_man_eater attribute_003_pet attribute_005_lives_in_water attribute_010_scales))
   (WMFCAImplication (attribute_002_man_eater attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_000_eggs attribute_001_nocturnal attribute_004_livestock attribute_005_lives_in_water attribute_010_scales))
   (WMFCAImplication (attribute_002_man_eater attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_000_eggs attribute_001_nocturnal attribute_003_pet attribute_005_lives_in_water attribute_010_scales))))

; Cover direction follows intent inclusion: general intent -> specific intent.
(= (wm-fca-animals-oracle-covers)
   (
   (WMFCACover () (attribute_000_eggs))
   (WMFCACover () (attribute_002_man_eater))
   (WMFCACover () (attribute_005_lives_in_water))
   (WMFCACover () (attribute_006_airbreather))
   (WMFCACover () (attribute_010_scales))
   (WMFCACover (attribute_000_eggs) (attribute_000_eggs attribute_006_airbreather))
   (WMFCACover (attribute_000_eggs) (attribute_000_eggs attribute_010_scales))
   (WMFCACover (attribute_002_man_eater) (attribute_002_man_eater attribute_005_lives_in_water attribute_010_scales))
   (WMFCACover (attribute_002_man_eater) (attribute_002_man_eater attribute_006_airbreather attribute_008_four_legged))
   (WMFCACover (attribute_005_lives_in_water) (attribute_005_lives_in_water attribute_006_airbreather))
   (WMFCACover (attribute_005_lives_in_water) (attribute_005_lives_in_water attribute_010_scales))
   (WMFCACover (attribute_006_airbreather) (attribute_000_eggs attribute_006_airbreather))
   (WMFCACover (attribute_006_airbreather) (attribute_001_nocturnal attribute_006_airbreather))
   (WMFCACover (attribute_006_airbreather) (attribute_005_lives_in_water attribute_006_airbreather))
   (WMFCACover (attribute_006_airbreather) (attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_006_airbreather) (attribute_006_airbreather attribute_008_four_legged))
   (WMFCACover (attribute_010_scales) (attribute_000_eggs attribute_010_scales))
   (WMFCACover (attribute_010_scales) (attribute_005_lives_in_water attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_006_airbreather) (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather))
   (WMFCACover (attribute_000_eggs attribute_006_airbreather) (attribute_000_eggs attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_000_eggs attribute_006_airbreather) (attribute_000_eggs attribute_006_airbreather attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_010_scales) (attribute_000_eggs attribute_005_lives_in_water attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_010_scales) (attribute_000_eggs attribute_006_airbreather attribute_010_scales))
   (WMFCACover (attribute_001_nocturnal attribute_006_airbreather) (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather))
   (WMFCACover (attribute_001_nocturnal attribute_006_airbreather) (attribute_001_nocturnal attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_005_lives_in_water attribute_006_airbreather) (attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_005_lives_in_water attribute_006_airbreather) (attribute_000_eggs attribute_002_man_eater attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCACover (attribute_005_lives_in_water attribute_010_scales) (attribute_000_eggs attribute_005_lives_in_water attribute_010_scales))
   (WMFCACover (attribute_005_lives_in_water attribute_010_scales) (attribute_002_man_eater attribute_005_lives_in_water attribute_010_scales))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded) (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded) (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded) (attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded) (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged))
   (WMFCACover (attribute_006_airbreather attribute_008_four_legged) (attribute_002_man_eater attribute_006_airbreather attribute_008_four_legged))
   (WMFCACover (attribute_006_airbreather attribute_008_four_legged) (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged))
   (WMFCACover (attribute_006_airbreather attribute_008_four_legged) (attribute_000_eggs attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather) (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_005_lives_in_water attribute_010_scales) (attribute_000_eggs attribute_002_man_eater attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_003_pet attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_000_eggs attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_000_eggs attribute_006_airbreather attribute_010_scales) (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_006_airbreather attribute_010_scales) (attribute_000_eggs attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCACover (attribute_002_man_eater attribute_005_lives_in_water attribute_010_scales) (attribute_000_eggs attribute_002_man_eater attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCACover (attribute_002_man_eater attribute_006_airbreather attribute_008_four_legged) (attribute_002_man_eater attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_002_man_eater attribute_006_airbreather attribute_008_four_legged) (attribute_000_eggs attribute_002_man_eater attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCACover (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_003_pet attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded) (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded))
   (WMFCACover (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded) (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged) (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_000_eggs attribute_001_nocturnal attribute_006_airbreather attribute_010_scales) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_003_pet attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_006_airbreather attribute_008_four_legged attribute_010_scales) (attribute_000_eggs attribute_002_man_eater attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged attribute_010_scales))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_001_nocturnal attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_002_man_eater attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_001_nocturnal attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_001_nocturnal attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_002_man_eater attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCACover (attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_001_nocturnal attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur))
   (WMFCACover (attribute_004_livestock attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCACover (attribute_000_eggs attribute_002_man_eater attribute_005_lives_in_water attribute_006_airbreather attribute_008_four_legged attribute_010_scales) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))
   (WMFCACover (attribute_001_nocturnal attribute_003_pet attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur) (attribute_000_eggs attribute_001_nocturnal attribute_002_man_eater attribute_003_pet attribute_004_livestock attribute_005_lives_in_water attribute_006_airbreather attribute_007_warmblooded attribute_008_four_legged attribute_009_fur attribute_010_scales))))
