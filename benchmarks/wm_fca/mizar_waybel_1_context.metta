; Generated from a pinned public Formal Concept Analysis context.
; Source: https://github.com/zariuq/MeTTapedia/blob/f93a93f7d4d62d90e22812295b7e46c036458603/lean/mettapedia/artifacts/concept_ontology/mizar_family/waybel_1.cxt
; SHA-256: 282ad2a6ed4d95982b7a4a8c8ea8a13b5b6fb3a4333e3007601c4df0c52d7047
;
; The context is complete: all 119 x 16 cells are
; explicit observations.  Matrix zeroes are WMFalse, never WMMissing.  A single
; dependence group records that the cells belong to one complete positive-occurrence article context.

!(import! &self lib_wm_fca)

(= (wm-fca-mizar_waybel_1-objects)
   (object_000_definition_1 object_001_definition_2 object_002_definition_4 object_003_notation_1 object_004_definition_5 object_005_definition_6 object_006_theorem_6 object_007_theorem_7 object_008_definition_7 object_009_definition_8 object_010_definition_9 object_011_theorem_8 object_012_definition_10 object_013_definition_11 object_014_theorem_9 object_015_theorem_10 object_016_theorem_11 object_017_theorem_12 object_018_registration_3 object_019_theorem_13 object_020_registration_4 object_021_theorem_14 object_022_theorem_15 object_023_theorem_16 object_024_theorem_17 object_025_theorem_18 object_026_theorem_19 object_027_theorem_20 object_028_theorem_21 object_029_theorem_22 object_030_theorem_23 object_031_theorem_24 object_032_theorem_25 object_033_theorem_26 object_034_theorem_27 object_035_definition_12 object_036_registration_6 object_037_definition_13 object_038_registration_7 object_039_registration_8 object_040_definition_14 object_041_registration_10 object_042_registration_11 object_043_registration_12 object_044_theorem_28 object_045_theorem_29 object_046_definition_15 object_047_theorem_30 object_048_registration_13 object_049_theorem_31 object_050_definition_16 object_051_registration_14 object_052_theorem_32 object_053_theorem_33 object_054_theorem_34 object_055_theorem_35 object_056_theorem_36 object_057_theorem_37 object_058_theorem_38 object_059_theorem_39 object_060_theorem_40 object_061_theorem_41 object_062_theorem_42 object_063_theorem_43 object_064_theorem_44 object_065_theorem_45 object_066_theorem_46 object_067_theorem_47 object_068_theorem_48 object_069_theorem_49 object_070_theorem_50 object_071_theorem_51 object_072_theorem_52 object_073_theorem_53 object_074_theorem_54 object_075_theorem_55 object_076_theorem_56 object_077_theorem_57 object_078_theorem_58 object_079_definition_17 object_080_theorem_62 object_081_theorem_63 object_082_theorem_64 object_083_definition_18 object_084_registration_16 object_085_definition_19 object_086_theorem_66 object_087_registration_17 object_088_theorem_67 object_089_theorem_68 object_090_registration_18 object_091_theorem_69 object_092_theorem_70 object_093_theorem_71 object_094_theorem_72 object_095_theorem_73 object_096_theorem_74 object_097_theorem_75 object_098_theorem_76 object_099_theorem_77 object_100_theorem_78 object_101_theorem_79 object_102_theorem_80 object_103_theorem_81 object_104_theorem_82 object_105_theorem_83 object_106_theorem_84 object_107_theorem_85 object_108_definition_22 object_109_definition_23 object_110_registration_19 object_111_theorem_86 object_112_theorem_87 object_113_definition_24 object_114_registration_20 object_115_registration_21 object_116_registration_22 object_117_registration_23 object_118_registration_24))

(= (wm-fca-mizar_waybel_1-attributes)
   (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))

(= (wm-fca-mizar_waybel_1-state)
   (WMFCAState
     (object_000_definition_1 object_001_definition_2 object_002_definition_4 object_003_notation_1 object_004_definition_5 object_005_definition_6 object_006_theorem_6 object_007_theorem_7 object_008_definition_7 object_009_definition_8 object_010_definition_9 object_011_theorem_8 object_012_definition_10 object_013_definition_11 object_014_theorem_9 object_015_theorem_10 object_016_theorem_11 object_017_theorem_12 object_018_registration_3 object_019_theorem_13 object_020_registration_4 object_021_theorem_14 object_022_theorem_15 object_023_theorem_16 object_024_theorem_17 object_025_theorem_18 object_026_theorem_19 object_027_theorem_20 object_028_theorem_21 object_029_theorem_22 object_030_theorem_23 object_031_theorem_24 object_032_theorem_25 object_033_theorem_26 object_034_theorem_27 object_035_definition_12 object_036_registration_6 object_037_definition_13 object_038_registration_7 object_039_registration_8 object_040_definition_14 object_041_registration_10 object_042_registration_11 object_043_registration_12 object_044_theorem_28 object_045_theorem_29 object_046_definition_15 object_047_theorem_30 object_048_registration_13 object_049_theorem_31 object_050_definition_16 object_051_registration_14 object_052_theorem_32 object_053_theorem_33 object_054_theorem_34 object_055_theorem_35 object_056_theorem_36 object_057_theorem_37 object_058_theorem_38 object_059_theorem_39 object_060_theorem_40 object_061_theorem_41 object_062_theorem_42 object_063_theorem_43 object_064_theorem_44 object_065_theorem_45 object_066_theorem_46 object_067_theorem_47 object_068_theorem_48 object_069_theorem_49 object_070_theorem_50 object_071_theorem_51 object_072_theorem_52 object_073_theorem_53 object_074_theorem_54 object_075_theorem_55 object_076_theorem_56 object_077_theorem_57 object_078_theorem_58 object_079_definition_17 object_080_theorem_62 object_081_theorem_63 object_082_theorem_64 object_083_definition_18 object_084_registration_16 object_085_definition_19 object_086_theorem_66 object_087_registration_17 object_088_theorem_67 object_089_theorem_68 object_090_registration_18 object_091_theorem_69 object_092_theorem_70 object_093_theorem_71 object_094_theorem_72 object_095_theorem_73 object_096_theorem_74 object_097_theorem_75 object_098_theorem_76 object_099_theorem_77 object_100_theorem_78 object_101_theorem_79 object_102_theorem_80 object_103_theorem_81 object_104_theorem_82 object_105_theorem_83 object_106_theorem_84 object_107_theorem_85 object_108_definition_22 object_109_definition_23 object_110_registration_19 object_111_theorem_86 object_112_theorem_87 object_113_definition_24 object_114_registration_20 object_115_registration_21 object_116_registration_22 object_117_registration_23 object_118_registration_24)
     (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint)
     (
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_001_connection WMFalse
  mizar_waybel_1-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_002_function WMTrue
  mizar_waybel_1-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_003_galois WMFalse
  mizar_waybel_1-cell-000-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-000-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_005_image WMFalse
  mizar_waybel_1-cell-000-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-000-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-000-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-000-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-000-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-000-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-000-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-000-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-000-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-000-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_000_definition_1 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-000-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-001-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_001_connection WMFalse
  mizar_waybel_1-cell-001-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_002_function WMTrue
  mizar_waybel_1-cell-001-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_003_galois WMFalse
  mizar_waybel_1-cell-001-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-001-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_005_image WMFalse
  mizar_waybel_1-cell-001-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-001-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-001-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-001-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-001-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-001-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-001-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-001-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-001-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-001-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_001_definition_2 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-001-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-002-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_001_connection WMFalse
  mizar_waybel_1-cell-002-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_002_function WMFalse
  mizar_waybel_1-cell-002-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_003_galois WMFalse
  mizar_waybel_1-cell-002-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-002-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_005_image WMFalse
  mizar_waybel_1-cell-002-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-002-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-002-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-002-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_009_ex_max_of WMTrue
  mizar_waybel_1-cell-002-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_010_ex_min_of WMTrue
  mizar_waybel_1-cell-002-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-002-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-002-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-002-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-002-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_002_definition_4 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-002-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-003-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_001_connection WMFalse
  mizar_waybel_1-cell-003-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_002_function WMFalse
  mizar_waybel_1-cell-003-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_003_galois WMFalse
  mizar_waybel_1-cell-003-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-003-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_005_image WMFalse
  mizar_waybel_1-cell-003-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-003-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-003-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-003-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_009_ex_max_of WMTrue
  mizar_waybel_1-cell-003-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_010_ex_min_of WMTrue
  mizar_waybel_1-cell-003-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-003-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-003-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-003-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-003-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_003_notation_1 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-003-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-004-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_001_connection WMFalse
  mizar_waybel_1-cell-004-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_002_function WMFalse
  mizar_waybel_1-cell-004-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_003_galois WMFalse
  mizar_waybel_1-cell-004-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-004-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_005_image WMFalse
  mizar_waybel_1-cell-004-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-004-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-004-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-004-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-004-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-004-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-004-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-004-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_013_is_minimum_of WMTrue
  mizar_waybel_1-cell-004-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-004-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_004_definition_5 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-004-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-005-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_001_connection WMFalse
  mizar_waybel_1-cell-005-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_002_function WMTrue
  mizar_waybel_1-cell-005-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_003_galois WMFalse
  mizar_waybel_1-cell-005-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-005-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_005_image WMFalse
  mizar_waybel_1-cell-005-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-005-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-005-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_008_are_isomorphic WMTrue
  mizar_waybel_1-cell-005-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-005-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-005-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-005-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-005-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-005-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-005-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_005_definition_6 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-005-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-006-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_001_connection WMFalse
  mizar_waybel_1-cell-006-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_002_function WMTrue
  mizar_waybel_1-cell-006-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_003_galois WMFalse
  mizar_waybel_1-cell-006-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-006-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_005_image WMFalse
  mizar_waybel_1-cell-006-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-006-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-006-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_008_are_isomorphic WMTrue
  mizar_waybel_1-cell-006-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-006-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-006-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-006-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-006-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-006-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-006-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_006_theorem_6 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-006-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-007-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_001_connection WMFalse
  mizar_waybel_1-cell-007-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_002_function WMTrue
  mizar_waybel_1-cell-007-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_003_galois WMTrue
  mizar_waybel_1-cell-007-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-007-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_005_image WMFalse
  mizar_waybel_1-cell-007-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-007-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-007-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_008_are_isomorphic WMTrue
  mizar_waybel_1-cell-007-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-007-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-007-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-007-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-007-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-007-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-007-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_007_theorem_7 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-007-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-008-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_001_connection WMTrue
  mizar_waybel_1-cell-008-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_002_function WMTrue
  mizar_waybel_1-cell-008-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_003_galois WMFalse
  mizar_waybel_1-cell-008-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-008-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_005_image WMFalse
  mizar_waybel_1-cell-008-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-008-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-008-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-008-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-008-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-008-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-008-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-008-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-008-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-008-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_008_definition_7 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-008-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-009-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_001_connection WMTrue
  mizar_waybel_1-cell-009-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_002_function WMTrue
  mizar_waybel_1-cell-009-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_003_galois WMFalse
  mizar_waybel_1-cell-009-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-009-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_005_image WMFalse
  mizar_waybel_1-cell-009-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-009-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-009-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-009-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-009-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-009-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-009-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-009-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-009-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-009-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_009_definition_8 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-009-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-010-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_001_connection WMTrue
  mizar_waybel_1-cell-010-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_002_function WMTrue
  mizar_waybel_1-cell-010-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_003_galois WMTrue
  mizar_waybel_1-cell-010-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-010-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_005_image WMFalse
  mizar_waybel_1-cell-010-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-010-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-010-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-010-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-010-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-010-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-010-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-010-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-010-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-010-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_010_definition_9 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-010-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-011-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_001_connection WMFalse
  mizar_waybel_1-cell-011-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_002_function WMTrue
  mizar_waybel_1-cell-011-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_003_galois WMTrue
  mizar_waybel_1-cell-011-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-011-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_005_image WMFalse
  mizar_waybel_1-cell-011-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-011-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-011-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-011-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-011-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-011-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-011-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-011-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-011-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-011-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_011_theorem_8 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-011-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-012-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_001_connection WMFalse
  mizar_waybel_1-cell-012-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_002_function WMTrue
  mizar_waybel_1-cell-012-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_003_galois WMTrue
  mizar_waybel_1-cell-012-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-012-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_005_image WMFalse
  mizar_waybel_1-cell-012-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-012-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-012-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-012-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-012-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-012-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-012-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-012-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-012-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-012-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_012_definition_10 attribute_015_upper_adjoint WMTrue
  mizar_waybel_1-cell-012-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-013-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_001_connection WMFalse
  mizar_waybel_1-cell-013-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_002_function WMTrue
  mizar_waybel_1-cell-013-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_003_galois WMTrue
  mizar_waybel_1-cell-013-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-013-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_005_image WMFalse
  mizar_waybel_1-cell-013-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-013-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-013-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-013-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-013-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-013-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-013-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-013-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-013-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-013-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_013_definition_11 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-013-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-014-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_001_connection WMFalse
  mizar_waybel_1-cell-014-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_002_function WMTrue
  mizar_waybel_1-cell-014-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_003_galois WMTrue
  mizar_waybel_1-cell-014-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-014-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_005_image WMFalse
  mizar_waybel_1-cell-014-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-014-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-014-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-014-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-014-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-014-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-014-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-014-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-014-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-014-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_014_theorem_9 attribute_015_upper_adjoint WMTrue
  mizar_waybel_1-cell-014-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-015-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_001_connection WMFalse
  mizar_waybel_1-cell-015-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_002_function WMTrue
  mizar_waybel_1-cell-015-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_003_galois WMTrue
  mizar_waybel_1-cell-015-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-015-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_005_image WMFalse
  mizar_waybel_1-cell-015-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-015-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-015-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-015-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-015-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-015-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-015-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-015-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_013_is_minimum_of WMTrue
  mizar_waybel_1-cell-015-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-015-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_015_theorem_10 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-015-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-016-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_001_connection WMFalse
  mizar_waybel_1-cell-016-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_002_function WMTrue
  mizar_waybel_1-cell-016-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_003_galois WMTrue
  mizar_waybel_1-cell-016-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-016-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_005_image WMFalse
  mizar_waybel_1-cell-016-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-016-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-016-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-016-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-016-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-016-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-016-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-016-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-016-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-016-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_016_theorem_11 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-016-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-017-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_001_connection WMFalse
  mizar_waybel_1-cell-017-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_002_function WMTrue
  mizar_waybel_1-cell-017-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_003_galois WMTrue
  mizar_waybel_1-cell-017-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-017-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_005_image WMFalse
  mizar_waybel_1-cell-017-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-017-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-017-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-017-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-017-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-017-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-017-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-017-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-017-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-017-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_017_theorem_12 attribute_015_upper_adjoint WMTrue
  mizar_waybel_1-cell-017-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-018-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_001_connection WMFalse
  mizar_waybel_1-cell-018-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_002_function WMTrue
  mizar_waybel_1-cell-018-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_003_galois WMFalse
  mizar_waybel_1-cell-018-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-018-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_005_image WMFalse
  mizar_waybel_1-cell-018-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-018-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-018-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-018-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-018-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-018-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-018-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-018-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-018-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-018-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_018_registration_3 attribute_015_upper_adjoint WMTrue
  mizar_waybel_1-cell-018-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-019-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_001_connection WMFalse
  mizar_waybel_1-cell-019-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_002_function WMTrue
  mizar_waybel_1-cell-019-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_003_galois WMTrue
  mizar_waybel_1-cell-019-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-019-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_005_image WMFalse
  mizar_waybel_1-cell-019-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-019-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-019-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-019-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-019-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-019-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-019-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-019-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-019-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-019-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_019_theorem_13 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-019-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-020-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_001_connection WMFalse
  mizar_waybel_1-cell-020-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_002_function WMTrue
  mizar_waybel_1-cell-020-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_003_galois WMFalse
  mizar_waybel_1-cell-020-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-020-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_005_image WMFalse
  mizar_waybel_1-cell-020-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-020-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-020-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-020-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-020-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-020-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-020-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-020-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-020-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-020-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_020_registration_4 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-020-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-021-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_001_connection WMFalse
  mizar_waybel_1-cell-021-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_002_function WMTrue
  mizar_waybel_1-cell-021-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_003_galois WMTrue
  mizar_waybel_1-cell-021-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-021-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_005_image WMFalse
  mizar_waybel_1-cell-021-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-021-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-021-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-021-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-021-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-021-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-021-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-021-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_013_is_minimum_of WMTrue
  mizar_waybel_1-cell-021-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-021-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_021_theorem_14 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-021-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-022-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_001_connection WMFalse
  mizar_waybel_1-cell-022-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_002_function WMTrue
  mizar_waybel_1-cell-022-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_003_galois WMTrue
  mizar_waybel_1-cell-022-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-022-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_005_image WMFalse
  mizar_waybel_1-cell-022-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-022-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-022-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-022-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-022-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-022-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-022-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-022-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-022-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-022-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_022_theorem_15 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-022-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-023-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_001_connection WMFalse
  mizar_waybel_1-cell-023-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_002_function WMTrue
  mizar_waybel_1-cell-023-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_003_galois WMTrue
  mizar_waybel_1-cell-023-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-023-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_005_image WMFalse
  mizar_waybel_1-cell-023-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-023-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-023-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-023-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-023-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-023-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-023-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-023-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_013_is_minimum_of WMTrue
  mizar_waybel_1-cell-023-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-023-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_023_theorem_16 attribute_015_upper_adjoint WMTrue
  mizar_waybel_1-cell-023-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-024-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_001_connection WMFalse
  mizar_waybel_1-cell-024-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_002_function WMTrue
  mizar_waybel_1-cell-024-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_003_galois WMTrue
  mizar_waybel_1-cell-024-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-024-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_005_image WMFalse
  mizar_waybel_1-cell-024-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-024-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-024-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-024-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-024-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-024-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-024-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-024-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-024-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-024-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_024_theorem_17 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-024-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-025-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_001_connection WMFalse
  mizar_waybel_1-cell-025-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_002_function WMTrue
  mizar_waybel_1-cell-025-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_003_galois WMTrue
  mizar_waybel_1-cell-025-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-025-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_005_image WMFalse
  mizar_waybel_1-cell-025-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-025-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-025-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-025-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-025-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-025-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-025-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-025-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-025-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-025-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_025_theorem_18 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-025-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-026-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_001_connection WMFalse
  mizar_waybel_1-cell-026-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_002_function WMTrue
  mizar_waybel_1-cell-026-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_003_galois WMTrue
  mizar_waybel_1-cell-026-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-026-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_005_image WMFalse
  mizar_waybel_1-cell-026-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-026-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-026-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-026-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-026-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-026-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-026-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-026-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-026-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-026-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_026_theorem_19 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-026-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-027-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_001_connection WMFalse
  mizar_waybel_1-cell-027-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_002_function WMTrue
  mizar_waybel_1-cell-027-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_003_galois WMFalse
  mizar_waybel_1-cell-027-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-027-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_005_image WMFalse
  mizar_waybel_1-cell-027-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-027-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-027-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-027-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-027-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-027-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-027-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-027-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-027-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-027-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_027_theorem_20 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-027-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-028-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_001_connection WMFalse
  mizar_waybel_1-cell-028-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_002_function WMTrue
  mizar_waybel_1-cell-028-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_003_galois WMFalse
  mizar_waybel_1-cell-028-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-028-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_005_image WMFalse
  mizar_waybel_1-cell-028-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-028-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-028-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-028-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-028-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-028-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-028-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-028-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-028-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-028-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_028_theorem_21 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-028-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-029-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_001_connection WMFalse
  mizar_waybel_1-cell-029-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_002_function WMTrue
  mizar_waybel_1-cell-029-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_003_galois WMTrue
  mizar_waybel_1-cell-029-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-029-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_005_image WMFalse
  mizar_waybel_1-cell-029-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-029-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-029-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-029-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-029-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-029-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-029-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-029-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_013_is_minimum_of WMTrue
  mizar_waybel_1-cell-029-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-029-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_029_theorem_22 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-029-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-030-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_001_connection WMFalse
  mizar_waybel_1-cell-030-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_002_function WMTrue
  mizar_waybel_1-cell-030-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_003_galois WMFalse
  mizar_waybel_1-cell-030-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-030-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_005_image WMFalse
  mizar_waybel_1-cell-030-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-030-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-030-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-030-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-030-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-030-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-030-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-030-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_013_is_minimum_of WMTrue
  mizar_waybel_1-cell-030-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-030-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_030_theorem_23 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-030-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-031-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_001_connection WMFalse
  mizar_waybel_1-cell-031-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_002_function WMTrue
  mizar_waybel_1-cell-031-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_003_galois WMTrue
  mizar_waybel_1-cell-031-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-031-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_005_image WMFalse
  mizar_waybel_1-cell-031-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-031-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-031-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-031-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-031-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-031-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-031-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-031-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_013_is_minimum_of WMTrue
  mizar_waybel_1-cell-031-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-031-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_031_theorem_24 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-031-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-032-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_001_connection WMFalse
  mizar_waybel_1-cell-032-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_002_function WMTrue
  mizar_waybel_1-cell-032-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_003_galois WMTrue
  mizar_waybel_1-cell-032-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-032-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_005_image WMFalse
  mizar_waybel_1-cell-032-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-032-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-032-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-032-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-032-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-032-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-032-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-032-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-032-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-032-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_032_theorem_25 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-032-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-033-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_001_connection WMFalse
  mizar_waybel_1-cell-033-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_002_function WMTrue
  mizar_waybel_1-cell-033-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_003_galois WMFalse
  mizar_waybel_1-cell-033-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-033-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_005_image WMFalse
  mizar_waybel_1-cell-033-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-033-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-033-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-033-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-033-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-033-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-033-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-033-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-033-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-033-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_033_theorem_26 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-033-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-034-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_001_connection WMFalse
  mizar_waybel_1-cell-034-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_002_function WMTrue
  mizar_waybel_1-cell-034-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_003_galois WMTrue
  mizar_waybel_1-cell-034-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-034-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_005_image WMFalse
  mizar_waybel_1-cell-034-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-034-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-034-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-034-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-034-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-034-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-034-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-034-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-034-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-034-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_034_theorem_27 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-034-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-035-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_001_connection WMFalse
  mizar_waybel_1-cell-035-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_002_function WMTrue
  mizar_waybel_1-cell-035-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_003_galois WMFalse
  mizar_waybel_1-cell-035-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-035-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_005_image WMFalse
  mizar_waybel_1-cell-035-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-035-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-035-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-035-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-035-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-035-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-035-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-035-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-035-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-035-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_035_definition_12 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-035-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-036-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_001_connection WMFalse
  mizar_waybel_1-cell-036-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_002_function WMTrue
  mizar_waybel_1-cell-036-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_003_galois WMFalse
  mizar_waybel_1-cell-036-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-036-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_005_image WMFalse
  mizar_waybel_1-cell-036-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-036-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-036-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-036-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-036-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-036-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-036-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-036-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-036-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-036-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_036_registration_6 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-036-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-037-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_001_connection WMFalse
  mizar_waybel_1-cell-037-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_002_function WMTrue
  mizar_waybel_1-cell-037-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_003_galois WMFalse
  mizar_waybel_1-cell-037-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-037-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_005_image WMFalse
  mizar_waybel_1-cell-037-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-037-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-037-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-037-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-037-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-037-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-037-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-037-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-037-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-037-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_037_definition_13 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-037-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-038-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_001_connection WMFalse
  mizar_waybel_1-cell-038-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_002_function WMTrue
  mizar_waybel_1-cell-038-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_003_galois WMFalse
  mizar_waybel_1-cell-038-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-038-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_005_image WMFalse
  mizar_waybel_1-cell-038-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-038-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-038-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-038-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-038-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-038-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-038-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-038-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-038-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-038-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_038_registration_7 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-038-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-039-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_001_connection WMFalse
  mizar_waybel_1-cell-039-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_002_function WMTrue
  mizar_waybel_1-cell-039-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_003_galois WMFalse
  mizar_waybel_1-cell-039-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-039-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_005_image WMFalse
  mizar_waybel_1-cell-039-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-039-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-039-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-039-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-039-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-039-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-039-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-039-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-039-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-039-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_039_registration_8 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-039-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-040-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_001_connection WMFalse
  mizar_waybel_1-cell-040-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_002_function WMTrue
  mizar_waybel_1-cell-040-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_003_galois WMFalse
  mizar_waybel_1-cell-040-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-040-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_005_image WMFalse
  mizar_waybel_1-cell-040-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-040-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-040-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-040-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-040-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-040-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-040-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-040-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-040-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-040-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_040_definition_14 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-040-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-041-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_001_connection WMFalse
  mizar_waybel_1-cell-041-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_002_function WMTrue
  mizar_waybel_1-cell-041-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_003_galois WMFalse
  mizar_waybel_1-cell-041-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-041-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_005_image WMFalse
  mizar_waybel_1-cell-041-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-041-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-041-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-041-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-041-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-041-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-041-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-041-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-041-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-041-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_041_registration_10 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-041-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-042-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_001_connection WMFalse
  mizar_waybel_1-cell-042-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_002_function WMTrue
  mizar_waybel_1-cell-042-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_003_galois WMFalse
  mizar_waybel_1-cell-042-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-042-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_005_image WMFalse
  mizar_waybel_1-cell-042-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-042-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-042-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-042-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-042-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-042-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-042-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-042-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-042-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-042-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_042_registration_11 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-042-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-043-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_001_connection WMFalse
  mizar_waybel_1-cell-043-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_002_function WMTrue
  mizar_waybel_1-cell-043-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_003_galois WMFalse
  mizar_waybel_1-cell-043-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-043-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_005_image WMFalse
  mizar_waybel_1-cell-043-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-043-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-043-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-043-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-043-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-043-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-043-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-043-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-043-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-043-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_043_registration_12 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-043-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-044-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_001_connection WMFalse
  mizar_waybel_1-cell-044-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_002_function WMTrue
  mizar_waybel_1-cell-044-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_003_galois WMFalse
  mizar_waybel_1-cell-044-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-044-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_005_image WMFalse
  mizar_waybel_1-cell-044-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-044-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-044-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-044-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-044-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-044-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-044-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-044-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-044-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-044-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_044_theorem_28 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-044-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-045-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_001_connection WMFalse
  mizar_waybel_1-cell-045-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_002_function WMTrue
  mizar_waybel_1-cell-045-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_003_galois WMFalse
  mizar_waybel_1-cell-045-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-045-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_005_image WMFalse
  mizar_waybel_1-cell-045-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-045-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-045-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-045-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-045-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-045-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-045-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-045-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-045-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-045-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_045_theorem_29 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-045-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-046-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_001_connection WMFalse
  mizar_waybel_1-cell-046-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_002_function WMTrue
  mizar_waybel_1-cell-046-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_003_galois WMFalse
  mizar_waybel_1-cell-046-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-046-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_005_image WMTrue
  mizar_waybel_1-cell-046-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-046-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-046-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-046-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-046-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-046-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-046-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-046-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-046-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-046-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_046_definition_15 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-046-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-047-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_001_connection WMFalse
  mizar_waybel_1-cell-047-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_002_function WMTrue
  mizar_waybel_1-cell-047-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_003_galois WMFalse
  mizar_waybel_1-cell-047-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-047-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_005_image WMTrue
  mizar_waybel_1-cell-047-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-047-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-047-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-047-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-047-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-047-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-047-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-047-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-047-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-047-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_047_theorem_30 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-047-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-048-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_001_connection WMFalse
  mizar_waybel_1-cell-048-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_002_function WMTrue
  mizar_waybel_1-cell-048-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_003_galois WMFalse
  mizar_waybel_1-cell-048-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-048-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_005_image WMFalse
  mizar_waybel_1-cell-048-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-048-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-048-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-048-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-048-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-048-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-048-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-048-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-048-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-048-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_048_registration_13 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-048-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-049-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_001_connection WMFalse
  mizar_waybel_1-cell-049-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_002_function WMTrue
  mizar_waybel_1-cell-049-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_003_galois WMFalse
  mizar_waybel_1-cell-049-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-049-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_005_image WMFalse
  mizar_waybel_1-cell-049-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-049-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-049-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-049-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-049-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-049-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-049-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-049-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-049-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-049-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_049_theorem_31 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-049-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-050-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_001_connection WMFalse
  mizar_waybel_1-cell-050-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_002_function WMTrue
  mizar_waybel_1-cell-050-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_003_galois WMFalse
  mizar_waybel_1-cell-050-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-050-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_005_image WMTrue
  mizar_waybel_1-cell-050-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-050-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-050-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-050-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-050-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-050-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-050-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-050-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-050-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-050-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_050_definition_16 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-050-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-051-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_001_connection WMFalse
  mizar_waybel_1-cell-051-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_002_function WMTrue
  mizar_waybel_1-cell-051-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_003_galois WMFalse
  mizar_waybel_1-cell-051-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-051-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_005_image WMFalse
  mizar_waybel_1-cell-051-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_006_l1 WMTrue
  mizar_waybel_1-cell-051-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_007_l2 WMTrue
  mizar_waybel_1-cell-051-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-051-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-051-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-051-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-051-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-051-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-051-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-051-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_051_registration_14 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-051-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-052-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_001_connection WMFalse
  mizar_waybel_1-cell-052-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_002_function WMTrue
  mizar_waybel_1-cell-052-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_003_galois WMFalse
  mizar_waybel_1-cell-052-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-052-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_005_image WMTrue
  mizar_waybel_1-cell-052-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-052-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-052-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-052-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-052-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-052-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-052-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-052-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-052-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-052-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_052_theorem_32 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-052-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-053-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_001_connection WMFalse
  mizar_waybel_1-cell-053-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_002_function WMTrue
  mizar_waybel_1-cell-053-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_003_galois WMFalse
  mizar_waybel_1-cell-053-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-053-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_005_image WMTrue
  mizar_waybel_1-cell-053-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-053-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-053-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-053-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-053-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-053-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-053-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-053-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-053-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-053-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_053_theorem_33 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-053-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-054-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_001_connection WMFalse
  mizar_waybel_1-cell-054-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_002_function WMTrue
  mizar_waybel_1-cell-054-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_003_galois WMFalse
  mizar_waybel_1-cell-054-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-054-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_005_image WMTrue
  mizar_waybel_1-cell-054-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-054-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-054-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-054-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-054-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-054-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-054-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-054-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-054-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-054-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_054_theorem_34 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-054-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-055-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_001_connection WMFalse
  mizar_waybel_1-cell-055-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_002_function WMTrue
  mizar_waybel_1-cell-055-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_003_galois WMFalse
  mizar_waybel_1-cell-055-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-055-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_005_image WMFalse
  mizar_waybel_1-cell-055-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-055-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-055-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-055-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-055-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-055-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-055-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-055-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-055-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-055-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_055_theorem_35 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-055-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-056-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_001_connection WMFalse
  mizar_waybel_1-cell-056-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_002_function WMTrue
  mizar_waybel_1-cell-056-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_003_galois WMTrue
  mizar_waybel_1-cell-056-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-056-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_005_image WMTrue
  mizar_waybel_1-cell-056-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-056-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-056-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-056-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-056-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-056-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-056-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-056-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-056-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-056-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_056_theorem_36 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-056-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-057-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_001_connection WMFalse
  mizar_waybel_1-cell-057-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_002_function WMTrue
  mizar_waybel_1-cell-057-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_003_galois WMTrue
  mizar_waybel_1-cell-057-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-057-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_005_image WMTrue
  mizar_waybel_1-cell-057-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-057-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-057-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-057-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-057-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-057-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-057-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-057-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-057-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-057-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_057_theorem_37 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-057-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-058-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_001_connection WMFalse
  mizar_waybel_1-cell-058-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_002_function WMTrue
  mizar_waybel_1-cell-058-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_003_galois WMTrue
  mizar_waybel_1-cell-058-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-058-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_005_image WMFalse
  mizar_waybel_1-cell-058-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-058-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-058-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-058-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-058-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-058-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-058-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-058-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-058-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-058-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_058_theorem_38 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-058-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-059-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_001_connection WMFalse
  mizar_waybel_1-cell-059-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_002_function WMTrue
  mizar_waybel_1-cell-059-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_003_galois WMTrue
  mizar_waybel_1-cell-059-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-059-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_005_image WMTrue
  mizar_waybel_1-cell-059-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-059-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-059-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-059-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-059-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-059-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-059-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-059-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-059-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-059-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_059_theorem_39 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-059-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-060-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_001_connection WMFalse
  mizar_waybel_1-cell-060-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_002_function WMTrue
  mizar_waybel_1-cell-060-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_003_galois WMTrue
  mizar_waybel_1-cell-060-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-060-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_005_image WMTrue
  mizar_waybel_1-cell-060-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-060-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-060-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-060-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-060-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-060-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-060-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-060-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-060-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-060-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_060_theorem_40 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-060-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-061-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_001_connection WMFalse
  mizar_waybel_1-cell-061-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_002_function WMTrue
  mizar_waybel_1-cell-061-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_003_galois WMTrue
  mizar_waybel_1-cell-061-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-061-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_005_image WMFalse
  mizar_waybel_1-cell-061-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-061-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-061-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-061-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-061-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-061-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-061-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-061-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-061-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-061-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_061_theorem_41 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-061-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-062-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_001_connection WMFalse
  mizar_waybel_1-cell-062-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_002_function WMTrue
  mizar_waybel_1-cell-062-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_003_galois WMFalse
  mizar_waybel_1-cell-062-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-062-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_005_image WMFalse
  mizar_waybel_1-cell-062-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-062-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-062-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-062-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-062-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-062-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-062-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-062-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-062-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-062-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_062_theorem_42 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-062-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-063-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_001_connection WMFalse
  mizar_waybel_1-cell-063-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_002_function WMTrue
  mizar_waybel_1-cell-063-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_003_galois WMFalse
  mizar_waybel_1-cell-063-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-063-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_005_image WMFalse
  mizar_waybel_1-cell-063-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-063-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-063-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-063-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-063-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-063-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-063-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-063-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-063-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-063-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_063_theorem_43 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-063-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-064-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_001_connection WMFalse
  mizar_waybel_1-cell-064-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_002_function WMTrue
  mizar_waybel_1-cell-064-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_003_galois WMFalse
  mizar_waybel_1-cell-064-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-064-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_005_image WMFalse
  mizar_waybel_1-cell-064-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-064-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-064-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-064-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-064-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-064-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-064-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-064-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-064-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-064-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_064_theorem_44 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-064-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-065-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_001_connection WMFalse
  mizar_waybel_1-cell-065-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_002_function WMTrue
  mizar_waybel_1-cell-065-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_003_galois WMFalse
  mizar_waybel_1-cell-065-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-065-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_005_image WMFalse
  mizar_waybel_1-cell-065-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-065-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-065-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-065-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-065-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-065-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-065-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-065-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-065-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-065-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_065_theorem_45 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-065-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-066-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_001_connection WMFalse
  mizar_waybel_1-cell-066-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_002_function WMTrue
  mizar_waybel_1-cell-066-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_003_galois WMFalse
  mizar_waybel_1-cell-066-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-066-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_005_image WMFalse
  mizar_waybel_1-cell-066-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-066-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-066-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-066-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-066-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-066-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-066-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-066-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-066-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-066-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_066_theorem_46 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-066-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-067-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_001_connection WMFalse
  mizar_waybel_1-cell-067-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_002_function WMTrue
  mizar_waybel_1-cell-067-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_003_galois WMFalse
  mizar_waybel_1-cell-067-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-067-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_005_image WMFalse
  mizar_waybel_1-cell-067-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-067-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-067-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-067-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-067-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-067-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-067-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-067-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-067-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-067-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_067_theorem_47 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-067-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-068-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_001_connection WMFalse
  mizar_waybel_1-cell-068-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_002_function WMTrue
  mizar_waybel_1-cell-068-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_003_galois WMFalse
  mizar_waybel_1-cell-068-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-068-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_005_image WMFalse
  mizar_waybel_1-cell-068-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-068-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-068-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-068-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-068-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-068-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-068-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-068-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-068-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-068-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_068_theorem_48 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-068-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-069-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_001_connection WMFalse
  mizar_waybel_1-cell-069-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_002_function WMTrue
  mizar_waybel_1-cell-069-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_003_galois WMFalse
  mizar_waybel_1-cell-069-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-069-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_005_image WMFalse
  mizar_waybel_1-cell-069-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-069-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-069-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-069-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-069-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-069-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-069-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-069-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-069-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-069-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_069_theorem_49 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-069-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-070-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_001_connection WMFalse
  mizar_waybel_1-cell-070-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_002_function WMTrue
  mizar_waybel_1-cell-070-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_003_galois WMFalse
  mizar_waybel_1-cell-070-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-070-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_005_image WMFalse
  mizar_waybel_1-cell-070-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-070-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-070-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-070-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-070-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-070-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-070-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-070-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-070-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-070-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_070_theorem_50 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-070-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-071-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_001_connection WMFalse
  mizar_waybel_1-cell-071-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_002_function WMTrue
  mizar_waybel_1-cell-071-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_003_galois WMFalse
  mizar_waybel_1-cell-071-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-071-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_005_image WMTrue
  mizar_waybel_1-cell-071-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-071-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-071-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-071-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-071-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-071-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-071-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-071-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-071-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-071-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_071_theorem_51 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-071-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-072-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_001_connection WMFalse
  mizar_waybel_1-cell-072-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_002_function WMTrue
  mizar_waybel_1-cell-072-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_003_galois WMFalse
  mizar_waybel_1-cell-072-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-072-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_005_image WMTrue
  mizar_waybel_1-cell-072-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-072-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-072-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-072-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-072-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-072-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-072-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-072-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-072-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-072-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_072_theorem_52 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-072-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-073-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_001_connection WMFalse
  mizar_waybel_1-cell-073-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_002_function WMTrue
  mizar_waybel_1-cell-073-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_003_galois WMFalse
  mizar_waybel_1-cell-073-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-073-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_005_image WMTrue
  mizar_waybel_1-cell-073-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-073-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-073-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-073-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-073-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-073-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-073-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-073-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-073-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-073-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_073_theorem_53 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-073-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-074-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_001_connection WMFalse
  mizar_waybel_1-cell-074-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_002_function WMTrue
  mizar_waybel_1-cell-074-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_003_galois WMFalse
  mizar_waybel_1-cell-074-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-074-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_005_image WMTrue
  mizar_waybel_1-cell-074-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-074-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-074-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-074-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-074-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-074-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-074-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-074-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-074-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-074-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_074_theorem_54 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-074-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-075-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_001_connection WMFalse
  mizar_waybel_1-cell-075-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_002_function WMTrue
  mizar_waybel_1-cell-075-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_003_galois WMTrue
  mizar_waybel_1-cell-075-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-075-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_005_image WMTrue
  mizar_waybel_1-cell-075-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-075-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-075-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-075-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-075-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-075-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-075-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-075-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-075-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-075-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_075_theorem_55 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-075-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-076-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_001_connection WMFalse
  mizar_waybel_1-cell-076-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_002_function WMTrue
  mizar_waybel_1-cell-076-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_003_galois WMTrue
  mizar_waybel_1-cell-076-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-076-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_005_image WMTrue
  mizar_waybel_1-cell-076-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-076-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-076-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-076-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-076-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-076-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-076-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-076-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-076-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-076-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_076_theorem_56 attribute_015_upper_adjoint WMTrue
  mizar_waybel_1-cell-076-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-077-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_001_connection WMFalse
  mizar_waybel_1-cell-077-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_002_function WMFalse
  mizar_waybel_1-cell-077-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_003_galois WMTrue
  mizar_waybel_1-cell-077-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-077-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_005_image WMFalse
  mizar_waybel_1-cell-077-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-077-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-077-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-077-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-077-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-077-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-077-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-077-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-077-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-077-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_077_theorem_57 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-077-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-078-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_001_connection WMFalse
  mizar_waybel_1-cell-078-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_002_function WMFalse
  mizar_waybel_1-cell-078-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_003_galois WMTrue
  mizar_waybel_1-cell-078-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-078-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_005_image WMTrue
  mizar_waybel_1-cell-078-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-078-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-078-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_008_are_isomorphic WMTrue
  mizar_waybel_1-cell-078-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-078-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-078-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-078-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-078-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-078-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-078-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_078_theorem_58 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-078-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-079-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_001_connection WMFalse
  mizar_waybel_1-cell-079-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_002_function WMTrue
  mizar_waybel_1-cell-079-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_003_galois WMFalse
  mizar_waybel_1-cell-079-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-079-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_005_image WMFalse
  mizar_waybel_1-cell-079-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-079-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-079-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-079-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-079-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-079-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-079-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-079-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-079-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-079-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_079_definition_17 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-079-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-080-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_001_connection WMFalse
  mizar_waybel_1-cell-080-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_002_function WMTrue
  mizar_waybel_1-cell-080-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_003_galois WMTrue
  mizar_waybel_1-cell-080-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-080-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_005_image WMFalse
  mizar_waybel_1-cell-080-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-080-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-080-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-080-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_009_ex_max_of WMTrue
  mizar_waybel_1-cell-080-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-080-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-080-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-080-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-080-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-080-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_080_theorem_62 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-080-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-081-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_001_connection WMFalse
  mizar_waybel_1-cell-081-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_002_function WMFalse
  mizar_waybel_1-cell-081-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_003_galois WMFalse
  mizar_waybel_1-cell-081-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-081-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_005_image WMFalse
  mizar_waybel_1-cell-081-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-081-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-081-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-081-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-081-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-081-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-081-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-081-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-081-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-081-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_081_theorem_63 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-081-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-082-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_001_connection WMFalse
  mizar_waybel_1-cell-082-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_002_function WMFalse
  mizar_waybel_1-cell-082-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_003_galois WMFalse
  mizar_waybel_1-cell-082-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-082-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_005_image WMFalse
  mizar_waybel_1-cell-082-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-082-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-082-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-082-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-082-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-082-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-082-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-082-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-082-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-082-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_082_theorem_64 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-082-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-083-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_001_connection WMFalse
  mizar_waybel_1-cell-083-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_002_function WMFalse
  mizar_waybel_1-cell-083-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_003_galois WMFalse
  mizar_waybel_1-cell-083-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-083-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_005_image WMFalse
  mizar_waybel_1-cell-083-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-083-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-083-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-083-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-083-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-083-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-083-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-083-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-083-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-083-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_083_definition_18 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-083-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-084-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_001_connection WMFalse
  mizar_waybel_1-cell-084-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_002_function WMFalse
  mizar_waybel_1-cell-084-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_003_galois WMFalse
  mizar_waybel_1-cell-084-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-084-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_005_image WMFalse
  mizar_waybel_1-cell-084-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-084-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-084-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-084-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-084-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-084-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-084-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-084-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-084-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-084-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_084_registration_16 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-084-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-085-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_001_connection WMFalse
  mizar_waybel_1-cell-085-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_002_function WMTrue
  mizar_waybel_1-cell-085-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_003_galois WMTrue
  mizar_waybel_1-cell-085-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-085-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_005_image WMFalse
  mizar_waybel_1-cell-085-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-085-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-085-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-085-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-085-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-085-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-085-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-085-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-085-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-085-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_085_definition_19 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-085-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-086-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_001_connection WMFalse
  mizar_waybel_1-cell-086-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_002_function WMFalse
  mizar_waybel_1-cell-086-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_003_galois WMFalse
  mizar_waybel_1-cell-086-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-086-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_005_image WMFalse
  mizar_waybel_1-cell-086-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-086-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-086-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-086-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-086-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-086-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-086-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-086-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-086-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_014_lower_adjoint WMTrue
  mizar_waybel_1-cell-086-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_086_theorem_66 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-086-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-087-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_001_connection WMFalse
  mizar_waybel_1-cell-087-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_002_function WMFalse
  mizar_waybel_1-cell-087-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_003_galois WMFalse
  mizar_waybel_1-cell-087-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-087-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_005_image WMFalse
  mizar_waybel_1-cell-087-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-087-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-087-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-087-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-087-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-087-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-087-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-087-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-087-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-087-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_087_registration_17 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-087-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-088-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_001_connection WMFalse
  mizar_waybel_1-cell-088-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_002_function WMFalse
  mizar_waybel_1-cell-088-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_003_galois WMTrue
  mizar_waybel_1-cell-088-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-088-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_005_image WMFalse
  mizar_waybel_1-cell-088-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-088-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-088-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-088-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-088-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-088-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-088-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-088-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-088-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-088-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_088_theorem_67 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-088-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-089-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_001_connection WMFalse
  mizar_waybel_1-cell-089-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_002_function WMFalse
  mizar_waybel_1-cell-089-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_003_galois WMFalse
  mizar_waybel_1-cell-089-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-089-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_005_image WMFalse
  mizar_waybel_1-cell-089-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-089-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-089-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-089-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-089-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-089-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-089-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-089-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-089-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-089-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_089_theorem_68 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-089-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-090-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_001_connection WMFalse
  mizar_waybel_1-cell-090-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_002_function WMFalse
  mizar_waybel_1-cell-090-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_003_galois WMFalse
  mizar_waybel_1-cell-090-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-090-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_005_image WMFalse
  mizar_waybel_1-cell-090-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-090-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-090-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-090-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-090-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-090-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-090-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-090-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-090-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-090-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_090_registration_18 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-090-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-091-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_001_connection WMFalse
  mizar_waybel_1-cell-091-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_002_function WMFalse
  mizar_waybel_1-cell-091-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_003_galois WMFalse
  mizar_waybel_1-cell-091-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-091-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_005_image WMFalse
  mizar_waybel_1-cell-091-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-091-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-091-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-091-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-091-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-091-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-091-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-091-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-091-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-091-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_091_theorem_69 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-091-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-092-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_001_connection WMFalse
  mizar_waybel_1-cell-092-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_002_function WMFalse
  mizar_waybel_1-cell-092-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_003_galois WMFalse
  mizar_waybel_1-cell-092-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-092-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_005_image WMFalse
  mizar_waybel_1-cell-092-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-092-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-092-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-092-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-092-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-092-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-092-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-092-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-092-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-092-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_092_theorem_70 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-092-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-093-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_001_connection WMFalse
  mizar_waybel_1-cell-093-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_002_function WMFalse
  mizar_waybel_1-cell-093-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_003_galois WMFalse
  mizar_waybel_1-cell-093-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-093-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_005_image WMFalse
  mizar_waybel_1-cell-093-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-093-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-093-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-093-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-093-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-093-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-093-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-093-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-093-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-093-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_093_theorem_71 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-093-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-094-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_001_connection WMFalse
  mizar_waybel_1-cell-094-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_002_function WMFalse
  mizar_waybel_1-cell-094-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_003_galois WMFalse
  mizar_waybel_1-cell-094-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-094-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_005_image WMFalse
  mizar_waybel_1-cell-094-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-094-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-094-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-094-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-094-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-094-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-094-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-094-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-094-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-094-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_094_theorem_72 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-094-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-095-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_001_connection WMFalse
  mizar_waybel_1-cell-095-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_002_function WMFalse
  mizar_waybel_1-cell-095-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_003_galois WMFalse
  mizar_waybel_1-cell-095-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-095-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_005_image WMFalse
  mizar_waybel_1-cell-095-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-095-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-095-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-095-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-095-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-095-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-095-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-095-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-095-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-095-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_095_theorem_73 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-095-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-096-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_001_connection WMFalse
  mizar_waybel_1-cell-096-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_002_function WMFalse
  mizar_waybel_1-cell-096-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_003_galois WMFalse
  mizar_waybel_1-cell-096-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-096-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_005_image WMFalse
  mizar_waybel_1-cell-096-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-096-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-096-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-096-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-096-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-096-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-096-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-096-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-096-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-096-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_096_theorem_74 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-096-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-097-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_001_connection WMFalse
  mizar_waybel_1-cell-097-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_002_function WMFalse
  mizar_waybel_1-cell-097-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_003_galois WMFalse
  mizar_waybel_1-cell-097-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-097-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_005_image WMFalse
  mizar_waybel_1-cell-097-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-097-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-097-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-097-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-097-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-097-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-097-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-097-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-097-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-097-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_097_theorem_75 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-097-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-098-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_001_connection WMFalse
  mizar_waybel_1-cell-098-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_002_function WMFalse
  mizar_waybel_1-cell-098-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_003_galois WMFalse
  mizar_waybel_1-cell-098-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-098-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_005_image WMFalse
  mizar_waybel_1-cell-098-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-098-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-098-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-098-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-098-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-098-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-098-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-098-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-098-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-098-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_098_theorem_76 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-098-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-099-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_001_connection WMFalse
  mizar_waybel_1-cell-099-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_002_function WMFalse
  mizar_waybel_1-cell-099-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_003_galois WMFalse
  mizar_waybel_1-cell-099-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-099-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_005_image WMFalse
  mizar_waybel_1-cell-099-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-099-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-099-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-099-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-099-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-099-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-099-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-099-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-099-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-099-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_099_theorem_77 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-099-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-100-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_001_connection WMFalse
  mizar_waybel_1-cell-100-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_002_function WMFalse
  mizar_waybel_1-cell-100-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_003_galois WMFalse
  mizar_waybel_1-cell-100-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-100-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_005_image WMFalse
  mizar_waybel_1-cell-100-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-100-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-100-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-100-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-100-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-100-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-100-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-100-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-100-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-100-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_100_theorem_78 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-100-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-101-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_001_connection WMFalse
  mizar_waybel_1-cell-101-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_002_function WMFalse
  mizar_waybel_1-cell-101-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_003_galois WMFalse
  mizar_waybel_1-cell-101-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-101-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_005_image WMFalse
  mizar_waybel_1-cell-101-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-101-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-101-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-101-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_009_ex_max_of WMTrue
  mizar_waybel_1-cell-101-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-101-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-101-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_012_is_maximum_of WMTrue
  mizar_waybel_1-cell-101-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-101-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-101-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_101_theorem_79 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-101-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-102-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_001_connection WMFalse
  mizar_waybel_1-cell-102-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_002_function WMFalse
  mizar_waybel_1-cell-102-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_003_galois WMFalse
  mizar_waybel_1-cell-102-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-102-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_005_image WMFalse
  mizar_waybel_1-cell-102-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-102-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-102-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-102-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-102-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-102-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-102-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-102-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-102-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-102-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_102_theorem_80 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-102-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-103-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_001_connection WMFalse
  mizar_waybel_1-cell-103-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_002_function WMFalse
  mizar_waybel_1-cell-103-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_003_galois WMFalse
  mizar_waybel_1-cell-103-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-103-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_005_image WMFalse
  mizar_waybel_1-cell-103-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-103-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-103-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-103-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-103-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-103-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-103-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-103-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-103-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-103-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_103_theorem_81 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-103-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-104-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_001_connection WMFalse
  mizar_waybel_1-cell-104-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_002_function WMFalse
  mizar_waybel_1-cell-104-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_003_galois WMFalse
  mizar_waybel_1-cell-104-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-104-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_005_image WMFalse
  mizar_waybel_1-cell-104-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-104-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-104-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-104-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-104-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-104-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-104-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-104-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-104-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-104-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_104_theorem_82 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-104-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-105-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_001_connection WMFalse
  mizar_waybel_1-cell-105-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_002_function WMFalse
  mizar_waybel_1-cell-105-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_003_galois WMFalse
  mizar_waybel_1-cell-105-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-105-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_005_image WMFalse
  mizar_waybel_1-cell-105-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-105-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-105-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-105-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-105-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-105-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-105-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-105-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-105-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-105-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_105_theorem_83 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-105-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-106-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_001_connection WMFalse
  mizar_waybel_1-cell-106-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_002_function WMFalse
  mizar_waybel_1-cell-106-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_003_galois WMFalse
  mizar_waybel_1-cell-106-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-106-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_005_image WMFalse
  mizar_waybel_1-cell-106-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-106-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-106-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-106-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-106-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-106-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-106-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-106-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-106-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-106-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_106_theorem_84 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-106-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-107-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_001_connection WMFalse
  mizar_waybel_1-cell-107-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_002_function WMFalse
  mizar_waybel_1-cell-107-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_003_galois WMFalse
  mizar_waybel_1-cell-107-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-107-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_005_image WMFalse
  mizar_waybel_1-cell-107-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-107-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-107-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-107-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-107-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-107-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-107-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-107-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-107-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-107-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_107_theorem_85 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-107-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-108-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_001_connection WMFalse
  mizar_waybel_1-cell-108-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_002_function WMFalse
  mizar_waybel_1-cell-108-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_003_galois WMFalse
  mizar_waybel_1-cell-108-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-108-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_005_image WMFalse
  mizar_waybel_1-cell-108-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-108-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-108-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-108-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-108-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-108-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_011_is_a_complement_of WMTrue
  mizar_waybel_1-cell-108-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-108-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-108-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-108-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_108_definition_22 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-108-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-109-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_001_connection WMFalse
  mizar_waybel_1-cell-109-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_002_function WMFalse
  mizar_waybel_1-cell-109-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_003_galois WMFalse
  mizar_waybel_1-cell-109-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-109-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_005_image WMFalse
  mizar_waybel_1-cell-109-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-109-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-109-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-109-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-109-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-109-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_011_is_a_complement_of WMTrue
  mizar_waybel_1-cell-109-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-109-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-109-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-109-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_109_definition_23 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-109-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-110-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_001_connection WMFalse
  mizar_waybel_1-cell-110-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_002_function WMTrue
  mizar_waybel_1-cell-110-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_003_galois WMTrue
  mizar_waybel_1-cell-110-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-110-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_005_image WMFalse
  mizar_waybel_1-cell-110-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-110-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-110-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-110-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-110-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-110-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_011_is_a_complement_of WMTrue
  mizar_waybel_1-cell-110-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-110-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-110-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-110-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_110_registration_19 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-110-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-111-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_001_connection WMFalse
  mizar_waybel_1-cell-111-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_002_function WMFalse
  mizar_waybel_1-cell-111-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_003_galois WMFalse
  mizar_waybel_1-cell-111-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-111-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_005_image WMFalse
  mizar_waybel_1-cell-111-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-111-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-111-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-111-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-111-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-111-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_011_is_a_complement_of WMTrue
  mizar_waybel_1-cell-111-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-111-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-111-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-111-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_111_theorem_86 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-111-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_000_boolean WMFalse
  mizar_waybel_1-cell-112-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_001_connection WMFalse
  mizar_waybel_1-cell-112-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_002_function WMFalse
  mizar_waybel_1-cell-112-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_003_galois WMFalse
  mizar_waybel_1-cell-112-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-112-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_005_image WMFalse
  mizar_waybel_1-cell-112-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-112-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-112-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-112-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-112-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-112-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-112-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-112-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-112-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-112-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_112_theorem_87 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-112-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_000_boolean WMTrue
  mizar_waybel_1-cell-113-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_001_connection WMFalse
  mizar_waybel_1-cell-113-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_002_function WMFalse
  mizar_waybel_1-cell-113-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_003_galois WMFalse
  mizar_waybel_1-cell-113-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-113-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_005_image WMFalse
  mizar_waybel_1-cell-113-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-113-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-113-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-113-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-113-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-113-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-113-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-113-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-113-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-113-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_113_definition_24 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-113-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_000_boolean WMTrue
  mizar_waybel_1-cell-114-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_001_connection WMFalse
  mizar_waybel_1-cell-114-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_002_function WMFalse
  mizar_waybel_1-cell-114-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_003_galois WMFalse
  mizar_waybel_1-cell-114-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-114-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_005_image WMFalse
  mizar_waybel_1-cell-114-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-114-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-114-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-114-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-114-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-114-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-114-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-114-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-114-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-114-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_114_registration_20 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-114-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_000_boolean WMTrue
  mizar_waybel_1-cell-115-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_001_connection WMFalse
  mizar_waybel_1-cell-115-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_002_function WMFalse
  mizar_waybel_1-cell-115-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_003_galois WMFalse
  mizar_waybel_1-cell-115-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-115-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_005_image WMFalse
  mizar_waybel_1-cell-115-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-115-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-115-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-115-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-115-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-115-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-115-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-115-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-115-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-115-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_115_registration_21 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-115-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_000_boolean WMTrue
  mizar_waybel_1-cell-116-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_001_connection WMFalse
  mizar_waybel_1-cell-116-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_002_function WMFalse
  mizar_waybel_1-cell-116-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_003_galois WMFalse
  mizar_waybel_1-cell-116-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-116-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_005_image WMFalse
  mizar_waybel_1-cell-116-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-116-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-116-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-116-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-116-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-116-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-116-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-116-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-116-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-116-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_116_registration_22 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-116-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_000_boolean WMTrue
  mizar_waybel_1-cell-117-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_001_connection WMFalse
  mizar_waybel_1-cell-117-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_002_function WMFalse
  mizar_waybel_1-cell-117-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_003_galois WMFalse
  mizar_waybel_1-cell-117-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_004_heyting WMFalse
  mizar_waybel_1-cell-117-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_005_image WMFalse
  mizar_waybel_1-cell-117-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-117-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-117-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-117-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-117-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-117-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-117-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-117-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-117-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-117-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_117_registration_23 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-117-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_000_boolean WMTrue
  mizar_waybel_1-cell-118-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_001_connection WMFalse
  mizar_waybel_1-cell-118-001 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_002_function WMFalse
  mizar_waybel_1-cell-118-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_003_galois WMFalse
  mizar_waybel_1-cell-118-003 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_004_heyting WMTrue
  mizar_waybel_1-cell-118-004 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_005_image WMFalse
  mizar_waybel_1-cell-118-005 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_006_l1 WMFalse
  mizar_waybel_1-cell-118-006 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_007_l2 WMFalse
  mizar_waybel_1-cell-118-007 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_008_are_isomorphic WMFalse
  mizar_waybel_1-cell-118-008 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_009_ex_max_of WMFalse
  mizar_waybel_1-cell-118-009 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_010_ex_min_of WMFalse
  mizar_waybel_1-cell-118-010 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_011_is_a_complement_of WMFalse
  mizar_waybel_1-cell-118-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_012_is_maximum_of WMFalse
  mizar_waybel_1-cell-118-012 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_013_is_minimum_of WMFalse
  mizar_waybel_1-cell-118-013 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_014_lower_adjoint WMFalse
  mizar_waybel_1-cell-118-014 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)
     (WMFCAObservation mizar_waybel_1 object_118_registration_24 attribute_015_upper_adjoint WMFalse
  mizar_waybel_1-cell-118-015 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction))))

(= (wm-fca-mizar_waybel_1-oracle-intents)
   (
   ()
   (attribute_000_boolean)
   (attribute_002_function)
   (attribute_003_galois)
   (attribute_004_heyting)
   (attribute_005_image)
   (attribute_008_are_isomorphic)
   (attribute_009_ex_max_of)
   (attribute_011_is_a_complement_of)
   (attribute_012_is_maximum_of)
   (attribute_013_is_minimum_of)
   (attribute_014_lower_adjoint)
   (attribute_000_boolean attribute_004_heyting)
   (attribute_001_connection attribute_002_function)
   (attribute_002_function attribute_003_galois)
   (attribute_002_function attribute_005_image)
   (attribute_002_function attribute_012_is_maximum_of)
   (attribute_002_function attribute_013_is_minimum_of)
   (attribute_002_function attribute_014_lower_adjoint)
   (attribute_002_function attribute_015_upper_adjoint)
   (attribute_003_galois attribute_004_heyting)
   (attribute_003_galois attribute_005_image)
   (attribute_003_galois attribute_008_are_isomorphic)
   (attribute_003_galois attribute_014_lower_adjoint)
   (attribute_004_heyting attribute_011_is_a_complement_of)
   (attribute_004_heyting attribute_012_is_maximum_of)
   (attribute_004_heyting attribute_014_lower_adjoint)
   (attribute_009_ex_max_of attribute_010_ex_min_of)
   (attribute_009_ex_max_of attribute_012_is_maximum_of)
   (attribute_012_is_maximum_of attribute_013_is_minimum_of)
   (attribute_001_connection attribute_002_function attribute_003_galois)
   (attribute_002_function attribute_003_galois attribute_004_heyting)
   (attribute_002_function attribute_003_galois attribute_005_image)
   (attribute_002_function attribute_003_galois attribute_012_is_maximum_of)
   (attribute_002_function attribute_003_galois attribute_013_is_minimum_of)
   (attribute_002_function attribute_003_galois attribute_014_lower_adjoint)
   (attribute_002_function attribute_003_galois attribute_015_upper_adjoint)
   (attribute_002_function attribute_006_l1 attribute_007_l2)
   (attribute_003_galois attribute_005_image attribute_008_are_isomorphic)
   (attribute_004_heyting attribute_009_ex_max_of attribute_012_is_maximum_of)
   (attribute_002_function attribute_003_galois attribute_004_heyting attribute_011_is_a_complement_of)
   (attribute_002_function attribute_003_galois attribute_004_heyting attribute_012_is_maximum_of)
   (attribute_002_function attribute_003_galois attribute_005_image attribute_014_lower_adjoint)
   (attribute_002_function attribute_003_galois attribute_012_is_maximum_of attribute_014_lower_adjoint)
   (attribute_002_function attribute_003_galois attribute_013_is_minimum_of attribute_015_upper_adjoint)
   (attribute_002_function attribute_003_galois attribute_014_lower_adjoint attribute_015_upper_adjoint)
   (attribute_002_function attribute_005_image attribute_006_l1 attribute_007_l2)
   (attribute_002_function attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic)
   (attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_015_upper_adjoint)
   (attribute_002_function attribute_003_galois attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic)
   (attribute_002_function attribute_003_galois attribute_009_ex_max_of attribute_012_is_maximum_of attribute_014_lower_adjoint)
   (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint)))

(= (wm-fca-mizar_waybel_1-oracle-concepts)
   (
   (WMFCAConcept (object_000_definition_1 object_001_definition_2 object_002_definition_4 object_003_notation_1 object_004_definition_5 object_005_definition_6 object_006_theorem_6 object_007_theorem_7 object_008_definition_7 object_009_definition_8 object_010_definition_9 object_011_theorem_8 object_012_definition_10 object_013_definition_11 object_014_theorem_9 object_015_theorem_10 object_016_theorem_11 object_017_theorem_12 object_018_registration_3 object_019_theorem_13 object_020_registration_4 object_021_theorem_14 object_022_theorem_15 object_023_theorem_16 object_024_theorem_17 object_025_theorem_18 object_026_theorem_19 object_027_theorem_20 object_028_theorem_21 object_029_theorem_22 object_030_theorem_23 object_031_theorem_24 object_032_theorem_25 object_033_theorem_26 object_034_theorem_27 object_035_definition_12 object_036_registration_6 object_037_definition_13 object_038_registration_7 object_039_registration_8 object_040_definition_14 object_041_registration_10 object_042_registration_11 object_043_registration_12 object_044_theorem_28 object_045_theorem_29 object_046_definition_15 object_047_theorem_30 object_048_registration_13 object_049_theorem_31 object_050_definition_16 object_051_registration_14 object_052_theorem_32 object_053_theorem_33 object_054_theorem_34 object_055_theorem_35 object_056_theorem_36 object_057_theorem_37 object_058_theorem_38 object_059_theorem_39 object_060_theorem_40 object_061_theorem_41 object_062_theorem_42 object_063_theorem_43 object_064_theorem_44 object_065_theorem_45 object_066_theorem_46 object_067_theorem_47 object_068_theorem_48 object_069_theorem_49 object_070_theorem_50 object_071_theorem_51 object_072_theorem_52 object_073_theorem_53 object_074_theorem_54 object_075_theorem_55 object_076_theorem_56 object_077_theorem_57 object_078_theorem_58 object_079_definition_17 object_080_theorem_62 object_081_theorem_63 object_082_theorem_64 object_083_definition_18 object_084_registration_16 object_085_definition_19 object_086_theorem_66 object_087_registration_17 object_088_theorem_67 object_089_theorem_68 object_090_registration_18 object_091_theorem_69 object_092_theorem_70 object_093_theorem_71 object_094_theorem_72 object_095_theorem_73 object_096_theorem_74 object_097_theorem_75 object_098_theorem_76 object_099_theorem_77 object_100_theorem_78 object_101_theorem_79 object_102_theorem_80 object_103_theorem_81 object_104_theorem_82 object_105_theorem_83 object_106_theorem_84 object_107_theorem_85 object_108_definition_22 object_109_definition_23 object_110_registration_19 object_111_theorem_86 object_112_theorem_87 object_113_definition_24 object_114_registration_20 object_115_registration_21 object_116_registration_22 object_117_registration_23 object_118_registration_24) ())
   (WMFCAConcept (object_113_definition_24 object_114_registration_20 object_115_registration_21 object_116_registration_22 object_117_registration_23 object_118_registration_24) (attribute_000_boolean))
   (WMFCAConcept (object_000_definition_1 object_001_definition_2 object_005_definition_6 object_006_theorem_6 object_007_theorem_7 object_008_definition_7 object_009_definition_8 object_010_definition_9 object_011_theorem_8 object_012_definition_10 object_013_definition_11 object_014_theorem_9 object_015_theorem_10 object_016_theorem_11 object_017_theorem_12 object_018_registration_3 object_019_theorem_13 object_020_registration_4 object_021_theorem_14 object_022_theorem_15 object_023_theorem_16 object_024_theorem_17 object_025_theorem_18 object_026_theorem_19 object_027_theorem_20 object_028_theorem_21 object_029_theorem_22 object_030_theorem_23 object_031_theorem_24 object_032_theorem_25 object_033_theorem_26 object_034_theorem_27 object_035_definition_12 object_036_registration_6 object_037_definition_13 object_038_registration_7 object_039_registration_8 object_040_definition_14 object_041_registration_10 object_042_registration_11 object_043_registration_12 object_044_theorem_28 object_045_theorem_29 object_046_definition_15 object_047_theorem_30 object_048_registration_13 object_049_theorem_31 object_050_definition_16 object_051_registration_14 object_052_theorem_32 object_053_theorem_33 object_054_theorem_34 object_055_theorem_35 object_056_theorem_36 object_057_theorem_37 object_058_theorem_38 object_059_theorem_39 object_060_theorem_40 object_061_theorem_41 object_062_theorem_42 object_063_theorem_43 object_064_theorem_44 object_065_theorem_45 object_066_theorem_46 object_067_theorem_47 object_068_theorem_48 object_069_theorem_49 object_070_theorem_50 object_071_theorem_51 object_072_theorem_52 object_073_theorem_53 object_074_theorem_54 object_075_theorem_55 object_076_theorem_56 object_079_definition_17 object_080_theorem_62 object_085_definition_19 object_110_registration_19) (attribute_002_function))
   (WMFCAConcept (object_007_theorem_7 object_010_definition_9 object_011_theorem_8 object_012_definition_10 object_013_definition_11 object_014_theorem_9 object_015_theorem_10 object_016_theorem_11 object_017_theorem_12 object_019_theorem_13 object_021_theorem_14 object_022_theorem_15 object_023_theorem_16 object_024_theorem_17 object_025_theorem_18 object_026_theorem_19 object_029_theorem_22 object_031_theorem_24 object_032_theorem_25 object_034_theorem_27 object_056_theorem_36 object_057_theorem_37 object_058_theorem_38 object_059_theorem_39 object_060_theorem_40 object_061_theorem_41 object_075_theorem_55 object_076_theorem_56 object_077_theorem_57 object_078_theorem_58 object_080_theorem_62 object_085_definition_19 object_088_theorem_67 object_110_registration_19) (attribute_003_galois))
   (WMFCAConcept (object_076_theorem_56 object_083_definition_18 object_084_registration_16 object_085_definition_19 object_086_theorem_66 object_087_registration_17 object_088_theorem_67 object_089_theorem_68 object_090_registration_18 object_091_theorem_69 object_092_theorem_70 object_093_theorem_71 object_094_theorem_72 object_095_theorem_73 object_096_theorem_74 object_097_theorem_75 object_098_theorem_76 object_099_theorem_77 object_100_theorem_78 object_101_theorem_79 object_102_theorem_80 object_103_theorem_81 object_104_theorem_82 object_105_theorem_83 object_106_theorem_84 object_107_theorem_85 object_110_registration_19 object_111_theorem_86 object_112_theorem_87 object_116_registration_22 object_118_registration_24) (attribute_004_heyting))
   (WMFCAConcept (object_046_definition_15 object_047_theorem_30 object_050_definition_16 object_052_theorem_32 object_053_theorem_33 object_054_theorem_34 object_056_theorem_36 object_057_theorem_37 object_059_theorem_39 object_060_theorem_40 object_071_theorem_51 object_072_theorem_52 object_073_theorem_53 object_074_theorem_54 object_075_theorem_55 object_076_theorem_56 object_078_theorem_58) (attribute_005_image))
   (WMFCAConcept (object_005_definition_6 object_006_theorem_6 object_007_theorem_7 object_078_theorem_58) (attribute_008_are_isomorphic))
   (WMFCAConcept (object_002_definition_4 object_003_notation_1 object_080_theorem_62 object_101_theorem_79) (attribute_009_ex_max_of))
   (WMFCAConcept (object_108_definition_22 object_109_definition_23 object_110_registration_19 object_111_theorem_86) (attribute_011_is_a_complement_of))
   (WMFCAConcept (object_004_definition_5 object_016_theorem_11 object_022_theorem_15 object_024_theorem_17 object_032_theorem_25 object_033_theorem_26 object_034_theorem_27 object_080_theorem_62 object_085_definition_19 object_101_theorem_79) (attribute_012_is_maximum_of))
   (WMFCAConcept (object_004_definition_5 object_015_theorem_10 object_021_theorem_14 object_023_theorem_16 object_029_theorem_22 object_030_theorem_23 object_031_theorem_24) (attribute_013_is_minimum_of))
   (WMFCAConcept (object_013_definition_11 object_014_theorem_9 object_019_theorem_13 object_020_registration_4 object_024_theorem_17 object_075_theorem_55 object_077_theorem_57 object_080_theorem_62 object_081_theorem_63 object_082_theorem_64 object_083_definition_18 object_086_theorem_66) (attribute_014_lower_adjoint))
   (WMFCAConcept (object_116_registration_22 object_118_registration_24) (attribute_000_boolean attribute_004_heyting))
   (WMFCAConcept (object_008_definition_7 object_009_definition_8 object_010_definition_9) (attribute_001_connection attribute_002_function))
   (WMFCAConcept (object_007_theorem_7 object_010_definition_9 object_011_theorem_8 object_012_definition_10 object_013_definition_11 object_014_theorem_9 object_015_theorem_10 object_016_theorem_11 object_017_theorem_12 object_019_theorem_13 object_021_theorem_14 object_022_theorem_15 object_023_theorem_16 object_024_theorem_17 object_025_theorem_18 object_026_theorem_19 object_029_theorem_22 object_031_theorem_24 object_032_theorem_25 object_034_theorem_27 object_056_theorem_36 object_057_theorem_37 object_058_theorem_38 object_059_theorem_39 object_060_theorem_40 object_061_theorem_41 object_075_theorem_55 object_076_theorem_56 object_080_theorem_62 object_085_definition_19 object_110_registration_19) (attribute_002_function attribute_003_galois))
   (WMFCAConcept (object_046_definition_15 object_047_theorem_30 object_050_definition_16 object_052_theorem_32 object_053_theorem_33 object_054_theorem_34 object_056_theorem_36 object_057_theorem_37 object_059_theorem_39 object_060_theorem_40 object_071_theorem_51 object_072_theorem_52 object_073_theorem_53 object_074_theorem_54 object_075_theorem_55 object_076_theorem_56) (attribute_002_function attribute_005_image))
   (WMFCAConcept (object_016_theorem_11 object_022_theorem_15 object_024_theorem_17 object_032_theorem_25 object_033_theorem_26 object_034_theorem_27 object_080_theorem_62 object_085_definition_19) (attribute_002_function attribute_012_is_maximum_of))
   (WMFCAConcept (object_015_theorem_10 object_021_theorem_14 object_023_theorem_16 object_029_theorem_22 object_030_theorem_23 object_031_theorem_24) (attribute_002_function attribute_013_is_minimum_of))
   (WMFCAConcept (object_013_definition_11 object_014_theorem_9 object_019_theorem_13 object_020_registration_4 object_024_theorem_17 object_075_theorem_55 object_080_theorem_62) (attribute_002_function attribute_014_lower_adjoint))
   (WMFCAConcept (object_012_definition_10 object_014_theorem_9 object_017_theorem_12 object_018_registration_3 object_023_theorem_16 object_076_theorem_56) (attribute_002_function attribute_015_upper_adjoint))
   (WMFCAConcept (object_076_theorem_56 object_085_definition_19 object_088_theorem_67 object_110_registration_19) (attribute_003_galois attribute_004_heyting))
   (WMFCAConcept (object_056_theorem_36 object_057_theorem_37 object_059_theorem_39 object_060_theorem_40 object_075_theorem_55 object_076_theorem_56 object_078_theorem_58) (attribute_003_galois attribute_005_image))
   (WMFCAConcept (object_007_theorem_7 object_078_theorem_58) (attribute_003_galois attribute_008_are_isomorphic))
   (WMFCAConcept (object_013_definition_11 object_014_theorem_9 object_019_theorem_13 object_024_theorem_17 object_075_theorem_55 object_077_theorem_57 object_080_theorem_62) (attribute_003_galois attribute_014_lower_adjoint))
   (WMFCAConcept (object_110_registration_19 object_111_theorem_86) (attribute_004_heyting attribute_011_is_a_complement_of))
   (WMFCAConcept (object_085_definition_19 object_101_theorem_79) (attribute_004_heyting attribute_012_is_maximum_of))
   (WMFCAConcept (object_083_definition_18 object_086_theorem_66) (attribute_004_heyting attribute_014_lower_adjoint))
   (WMFCAConcept (object_002_definition_4 object_003_notation_1) (attribute_009_ex_max_of attribute_010_ex_min_of))
   (WMFCAConcept (object_080_theorem_62 object_101_theorem_79) (attribute_009_ex_max_of attribute_012_is_maximum_of))
   (WMFCAConcept (object_004_definition_5) (attribute_012_is_maximum_of attribute_013_is_minimum_of))
   (WMFCAConcept (object_010_definition_9) (attribute_001_connection attribute_002_function attribute_003_galois))
   (WMFCAConcept (object_076_theorem_56 object_085_definition_19 object_110_registration_19) (attribute_002_function attribute_003_galois attribute_004_heyting))
   (WMFCAConcept (object_056_theorem_36 object_057_theorem_37 object_059_theorem_39 object_060_theorem_40 object_075_theorem_55 object_076_theorem_56) (attribute_002_function attribute_003_galois attribute_005_image))
   (WMFCAConcept (object_016_theorem_11 object_022_theorem_15 object_024_theorem_17 object_032_theorem_25 object_034_theorem_27 object_080_theorem_62 object_085_definition_19) (attribute_002_function attribute_003_galois attribute_012_is_maximum_of))
   (WMFCAConcept (object_015_theorem_10 object_021_theorem_14 object_023_theorem_16 object_029_theorem_22 object_031_theorem_24) (attribute_002_function attribute_003_galois attribute_013_is_minimum_of))
   (WMFCAConcept (object_013_definition_11 object_014_theorem_9 object_019_theorem_13 object_024_theorem_17 object_075_theorem_55 object_080_theorem_62) (attribute_002_function attribute_003_galois attribute_014_lower_adjoint))
   (WMFCAConcept (object_012_definition_10 object_014_theorem_9 object_017_theorem_12 object_023_theorem_16 object_076_theorem_56) (attribute_002_function attribute_003_galois attribute_015_upper_adjoint))
   (WMFCAConcept (object_000_definition_1 object_001_definition_2 object_005_definition_6 object_006_theorem_6 object_007_theorem_7 object_038_registration_7 object_046_definition_15 object_047_theorem_30 object_048_registration_13 object_049_theorem_31 object_050_definition_16 object_051_registration_14) (attribute_002_function attribute_006_l1 attribute_007_l2))
   (WMFCAConcept (object_078_theorem_58) (attribute_003_galois attribute_005_image attribute_008_are_isomorphic))
   (WMFCAConcept (object_101_theorem_79) (attribute_004_heyting attribute_009_ex_max_of attribute_012_is_maximum_of))
   (WMFCAConcept (object_110_registration_19) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_011_is_a_complement_of))
   (WMFCAConcept (object_085_definition_19) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_012_is_maximum_of))
   (WMFCAConcept (object_075_theorem_55) (attribute_002_function attribute_003_galois attribute_005_image attribute_014_lower_adjoint))
   (WMFCAConcept (object_024_theorem_17 object_080_theorem_62) (attribute_002_function attribute_003_galois attribute_012_is_maximum_of attribute_014_lower_adjoint))
   (WMFCAConcept (object_023_theorem_16) (attribute_002_function attribute_003_galois attribute_013_is_minimum_of attribute_015_upper_adjoint))
   (WMFCAConcept (object_014_theorem_9) (attribute_002_function attribute_003_galois attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAConcept (object_046_definition_15 object_047_theorem_30 object_050_definition_16) (attribute_002_function attribute_005_image attribute_006_l1 attribute_007_l2))
   (WMFCAConcept (object_005_definition_6 object_006_theorem_6 object_007_theorem_7) (attribute_002_function attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic))
   (WMFCAConcept (object_076_theorem_56) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_015_upper_adjoint))
   (WMFCAConcept (object_007_theorem_7) (attribute_002_function attribute_003_galois attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic))
   (WMFCAConcept (object_080_theorem_62) (attribute_002_function attribute_003_galois attribute_009_ex_max_of attribute_012_is_maximum_of attribute_014_lower_adjoint))
   (WMFCAConcept () (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))))

(= (wm-fca-mizar_waybel_1-oracle-basis)
   (
   (WMFCAImplication (attribute_001_connection) (attribute_002_function))
   (WMFCAImplication (attribute_006_l1) (attribute_002_function attribute_007_l2))
   (WMFCAImplication (attribute_007_l2) (attribute_002_function attribute_006_l1))
   (WMFCAImplication (attribute_010_ex_min_of) (attribute_009_ex_max_of))
   (WMFCAImplication (attribute_015_upper_adjoint) (attribute_002_function))
   (WMFCAImplication (attribute_000_boolean attribute_002_function) (attribute_001_connection attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_000_boolean attribute_003_galois) (attribute_001_connection attribute_002_function attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_000_boolean attribute_005_image) (attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_000_boolean attribute_008_are_isomorphic) (attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_000_boolean attribute_009_ex_max_of) (attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_000_boolean attribute_011_is_a_complement_of) (attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_000_boolean attribute_012_is_maximum_of) (attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_000_boolean attribute_013_is_minimum_of) (attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_000_boolean attribute_014_lower_adjoint) (attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_002_function attribute_004_heyting) (attribute_003_galois))
   (WMFCAImplication (attribute_002_function attribute_008_are_isomorphic) (attribute_006_l1 attribute_007_l2))
   (WMFCAImplication (attribute_002_function attribute_009_ex_max_of) (attribute_003_galois attribute_012_is_maximum_of attribute_014_lower_adjoint))
   (WMFCAImplication (attribute_002_function attribute_011_is_a_complement_of) (attribute_003_galois attribute_004_heyting))
   (WMFCAImplication (attribute_003_galois attribute_009_ex_max_of) (attribute_002_function attribute_012_is_maximum_of attribute_014_lower_adjoint))
   (WMFCAImplication (attribute_003_galois attribute_011_is_a_complement_of) (attribute_002_function attribute_004_heyting))
   (WMFCAImplication (attribute_003_galois attribute_012_is_maximum_of) (attribute_002_function))
   (WMFCAImplication (attribute_003_galois attribute_013_is_minimum_of) (attribute_002_function))
   (WMFCAImplication (attribute_004_heyting attribute_005_image) (attribute_002_function attribute_003_galois attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_004_heyting attribute_008_are_isomorphic) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_005_image attribute_006_l1 attribute_007_l2 attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_004_heyting attribute_009_ex_max_of) (attribute_012_is_maximum_of))
   (WMFCAImplication (attribute_004_heyting attribute_013_is_minimum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_005_image attribute_008_are_isomorphic) (attribute_003_galois))
   (WMFCAImplication (attribute_005_image attribute_009_ex_max_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_005_image attribute_011_is_a_complement_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_005_image attribute_012_is_maximum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_005_image attribute_013_is_minimum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_005_image attribute_014_lower_adjoint) (attribute_002_function attribute_003_galois))
   (WMFCAImplication (attribute_008_are_isomorphic attribute_009_ex_max_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_008_are_isomorphic attribute_011_is_a_complement_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_009_ex_max_of attribute_010_ex_min_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_008_are_isomorphic attribute_012_is_maximum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_008_are_isomorphic attribute_013_is_minimum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_008_are_isomorphic attribute_014_lower_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_009_ex_max_of attribute_011_is_a_complement_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_010_ex_min_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_009_ex_max_of attribute_013_is_minimum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_009_ex_max_of attribute_014_lower_adjoint) (attribute_002_function attribute_003_galois attribute_012_is_maximum_of))
   (WMFCAImplication (attribute_011_is_a_complement_of attribute_012_is_maximum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_011_is_a_complement_of attribute_013_is_minimum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_012_is_maximum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_011_is_a_complement_of attribute_014_lower_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_012_is_maximum_of attribute_014_lower_adjoint) (attribute_002_function attribute_003_galois))
   (WMFCAImplication (attribute_013_is_minimum_of attribute_014_lower_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_001_connection attribute_002_function attribute_005_image) (attribute_000_boolean attribute_003_galois attribute_004_heyting attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_001_connection attribute_002_function attribute_012_is_maximum_of) (attribute_000_boolean attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_001_connection attribute_002_function attribute_013_is_minimum_of) (attribute_000_boolean attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_001_connection attribute_002_function attribute_014_lower_adjoint) (attribute_000_boolean attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_001_connection attribute_002_function attribute_015_upper_adjoint) (attribute_000_boolean attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint))
   (WMFCAImplication (attribute_002_function attribute_005_image attribute_015_upper_adjoint) (attribute_003_galois attribute_004_heyting))
   (WMFCAImplication (attribute_002_function attribute_012_is_maximum_of attribute_013_is_minimum_of) (attribute_000_boolean attribute_001_connection attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_002_function attribute_012_is_maximum_of attribute_015_upper_adjoint) (attribute_000_boolean attribute_001_connection attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_013_is_minimum_of attribute_014_lower_adjoint))
   (WMFCAImplication (attribute_002_function attribute_013_is_minimum_of attribute_015_upper_adjoint) (attribute_003_galois))
   (WMFCAImplication (attribute_002_function attribute_014_lower_adjoint attribute_015_upper_adjoint) (attribute_003_galois))
   (WMFCAImplication (attribute_003_galois attribute_004_heyting attribute_014_lower_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_009_ex_max_of attribute_010_ex_min_of attribute_012_is_maximum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_011_is_a_complement_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting) (attribute_000_boolean attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_001_connection attribute_002_function attribute_006_l1 attribute_007_l2) (attribute_000_boolean attribute_003_galois attribute_004_heyting attribute_005_image attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_002_function attribute_003_galois attribute_004_heyting attribute_015_upper_adjoint) (attribute_005_image))
   (WMFCAImplication (attribute_002_function attribute_003_galois attribute_006_l1 attribute_007_l2) (attribute_008_are_isomorphic))
   (WMFCAImplication (attribute_002_function attribute_006_l1 attribute_007_l2 attribute_012_is_maximum_of) (attribute_000_boolean attribute_001_connection attribute_003_galois attribute_004_heyting attribute_005_image attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_002_function attribute_006_l1 attribute_007_l2 attribute_013_is_minimum_of) (attribute_000_boolean attribute_001_connection attribute_003_galois attribute_004_heyting attribute_005_image attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_002_function attribute_006_l1 attribute_007_l2 attribute_014_lower_adjoint) (attribute_000_boolean attribute_001_connection attribute_003_galois attribute_004_heyting attribute_005_image attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_015_upper_adjoint))
   (WMFCAImplication (attribute_002_function attribute_006_l1 attribute_007_l2 attribute_015_upper_adjoint) (attribute_000_boolean attribute_001_connection attribute_003_galois attribute_004_heyting attribute_005_image attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint))
   (WMFCAImplication (attribute_002_function attribute_003_galois attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic) (attribute_000_boolean attribute_001_connection attribute_004_heyting attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))))

; Cover direction follows intent inclusion: general intent -> specific intent.
(= (wm-fca-mizar_waybel_1-oracle-covers)
   (
   (WMFCACover () (attribute_000_boolean))
   (WMFCACover () (attribute_002_function))
   (WMFCACover () (attribute_003_galois))
   (WMFCACover () (attribute_004_heyting))
   (WMFCACover () (attribute_005_image))
   (WMFCACover () (attribute_008_are_isomorphic))
   (WMFCACover () (attribute_009_ex_max_of))
   (WMFCACover () (attribute_011_is_a_complement_of))
   (WMFCACover () (attribute_012_is_maximum_of))
   (WMFCACover () (attribute_013_is_minimum_of))
   (WMFCACover () (attribute_014_lower_adjoint))
   (WMFCACover (attribute_000_boolean) (attribute_000_boolean attribute_004_heyting))
   (WMFCACover (attribute_002_function) (attribute_001_connection attribute_002_function))
   (WMFCACover (attribute_002_function) (attribute_002_function attribute_003_galois))
   (WMFCACover (attribute_002_function) (attribute_002_function attribute_005_image))
   (WMFCACover (attribute_002_function) (attribute_002_function attribute_012_is_maximum_of))
   (WMFCACover (attribute_002_function) (attribute_002_function attribute_013_is_minimum_of))
   (WMFCACover (attribute_002_function) (attribute_002_function attribute_014_lower_adjoint))
   (WMFCACover (attribute_002_function) (attribute_002_function attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function) (attribute_002_function attribute_006_l1 attribute_007_l2))
   (WMFCACover (attribute_003_galois) (attribute_002_function attribute_003_galois))
   (WMFCACover (attribute_003_galois) (attribute_003_galois attribute_004_heyting))
   (WMFCACover (attribute_003_galois) (attribute_003_galois attribute_005_image))
   (WMFCACover (attribute_003_galois) (attribute_003_galois attribute_008_are_isomorphic))
   (WMFCACover (attribute_003_galois) (attribute_003_galois attribute_014_lower_adjoint))
   (WMFCACover (attribute_004_heyting) (attribute_000_boolean attribute_004_heyting))
   (WMFCACover (attribute_004_heyting) (attribute_003_galois attribute_004_heyting))
   (WMFCACover (attribute_004_heyting) (attribute_004_heyting attribute_011_is_a_complement_of))
   (WMFCACover (attribute_004_heyting) (attribute_004_heyting attribute_012_is_maximum_of))
   (WMFCACover (attribute_004_heyting) (attribute_004_heyting attribute_014_lower_adjoint))
   (WMFCACover (attribute_005_image) (attribute_002_function attribute_005_image))
   (WMFCACover (attribute_005_image) (attribute_003_galois attribute_005_image))
   (WMFCACover (attribute_008_are_isomorphic) (attribute_003_galois attribute_008_are_isomorphic))
   (WMFCACover (attribute_008_are_isomorphic) (attribute_002_function attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic))
   (WMFCACover (attribute_009_ex_max_of) (attribute_009_ex_max_of attribute_010_ex_min_of))
   (WMFCACover (attribute_009_ex_max_of) (attribute_009_ex_max_of attribute_012_is_maximum_of))
   (WMFCACover (attribute_011_is_a_complement_of) (attribute_004_heyting attribute_011_is_a_complement_of))
   (WMFCACover (attribute_012_is_maximum_of) (attribute_002_function attribute_012_is_maximum_of))
   (WMFCACover (attribute_012_is_maximum_of) (attribute_004_heyting attribute_012_is_maximum_of))
   (WMFCACover (attribute_012_is_maximum_of) (attribute_009_ex_max_of attribute_012_is_maximum_of))
   (WMFCACover (attribute_012_is_maximum_of) (attribute_012_is_maximum_of attribute_013_is_minimum_of))
   (WMFCACover (attribute_013_is_minimum_of) (attribute_002_function attribute_013_is_minimum_of))
   (WMFCACover (attribute_013_is_minimum_of) (attribute_012_is_maximum_of attribute_013_is_minimum_of))
   (WMFCACover (attribute_014_lower_adjoint) (attribute_002_function attribute_014_lower_adjoint))
   (WMFCACover (attribute_014_lower_adjoint) (attribute_003_galois attribute_014_lower_adjoint))
   (WMFCACover (attribute_014_lower_adjoint) (attribute_004_heyting attribute_014_lower_adjoint))
   (WMFCACover (attribute_000_boolean attribute_004_heyting) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_001_connection attribute_002_function) (attribute_001_connection attribute_002_function attribute_003_galois))
   (WMFCACover (attribute_002_function attribute_003_galois) (attribute_001_connection attribute_002_function attribute_003_galois))
   (WMFCACover (attribute_002_function attribute_003_galois) (attribute_002_function attribute_003_galois attribute_004_heyting))
   (WMFCACover (attribute_002_function attribute_003_galois) (attribute_002_function attribute_003_galois attribute_005_image))
   (WMFCACover (attribute_002_function attribute_003_galois) (attribute_002_function attribute_003_galois attribute_012_is_maximum_of))
   (WMFCACover (attribute_002_function attribute_003_galois) (attribute_002_function attribute_003_galois attribute_013_is_minimum_of))
   (WMFCACover (attribute_002_function attribute_003_galois) (attribute_002_function attribute_003_galois attribute_014_lower_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois) (attribute_002_function attribute_003_galois attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois) (attribute_002_function attribute_003_galois attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic))
   (WMFCACover (attribute_002_function attribute_005_image) (attribute_002_function attribute_003_galois attribute_005_image))
   (WMFCACover (attribute_002_function attribute_005_image) (attribute_002_function attribute_005_image attribute_006_l1 attribute_007_l2))
   (WMFCACover (attribute_002_function attribute_012_is_maximum_of) (attribute_002_function attribute_003_galois attribute_012_is_maximum_of))
   (WMFCACover (attribute_002_function attribute_013_is_minimum_of) (attribute_002_function attribute_003_galois attribute_013_is_minimum_of))
   (WMFCACover (attribute_002_function attribute_014_lower_adjoint) (attribute_002_function attribute_003_galois attribute_014_lower_adjoint))
   (WMFCACover (attribute_002_function attribute_015_upper_adjoint) (attribute_002_function attribute_003_galois attribute_015_upper_adjoint))
   (WMFCACover (attribute_003_galois attribute_004_heyting) (attribute_002_function attribute_003_galois attribute_004_heyting))
   (WMFCACover (attribute_003_galois attribute_005_image) (attribute_002_function attribute_003_galois attribute_005_image))
   (WMFCACover (attribute_003_galois attribute_005_image) (attribute_003_galois attribute_005_image attribute_008_are_isomorphic))
   (WMFCACover (attribute_003_galois attribute_008_are_isomorphic) (attribute_003_galois attribute_005_image attribute_008_are_isomorphic))
   (WMFCACover (attribute_003_galois attribute_008_are_isomorphic) (attribute_002_function attribute_003_galois attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic))
   (WMFCACover (attribute_003_galois attribute_014_lower_adjoint) (attribute_002_function attribute_003_galois attribute_014_lower_adjoint))
   (WMFCACover (attribute_004_heyting attribute_011_is_a_complement_of) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_011_is_a_complement_of))
   (WMFCACover (attribute_004_heyting attribute_012_is_maximum_of) (attribute_004_heyting attribute_009_ex_max_of attribute_012_is_maximum_of))
   (WMFCACover (attribute_004_heyting attribute_012_is_maximum_of) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_012_is_maximum_of))
   (WMFCACover (attribute_004_heyting attribute_014_lower_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_009_ex_max_of attribute_010_ex_min_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_009_ex_max_of attribute_012_is_maximum_of) (attribute_004_heyting attribute_009_ex_max_of attribute_012_is_maximum_of))
   (WMFCACover (attribute_009_ex_max_of attribute_012_is_maximum_of) (attribute_002_function attribute_003_galois attribute_009_ex_max_of attribute_012_is_maximum_of attribute_014_lower_adjoint))
   (WMFCACover (attribute_012_is_maximum_of attribute_013_is_minimum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_001_connection attribute_002_function attribute_003_galois) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_004_heyting) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_011_is_a_complement_of))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_004_heyting) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_012_is_maximum_of))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_004_heyting) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_005_image) (attribute_002_function attribute_003_galois attribute_005_image attribute_014_lower_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_005_image) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_012_is_maximum_of) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_012_is_maximum_of))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_012_is_maximum_of) (attribute_002_function attribute_003_galois attribute_012_is_maximum_of attribute_014_lower_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_013_is_minimum_of) (attribute_002_function attribute_003_galois attribute_013_is_minimum_of attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_014_lower_adjoint) (attribute_002_function attribute_003_galois attribute_005_image attribute_014_lower_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_014_lower_adjoint) (attribute_002_function attribute_003_galois attribute_012_is_maximum_of attribute_014_lower_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_014_lower_adjoint) (attribute_002_function attribute_003_galois attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_015_upper_adjoint) (attribute_002_function attribute_003_galois attribute_013_is_minimum_of attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_015_upper_adjoint) (attribute_002_function attribute_003_galois attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_015_upper_adjoint) (attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_006_l1 attribute_007_l2) (attribute_002_function attribute_005_image attribute_006_l1 attribute_007_l2))
   (WMFCACover (attribute_002_function attribute_006_l1 attribute_007_l2) (attribute_002_function attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic))
   (WMFCACover (attribute_003_galois attribute_005_image attribute_008_are_isomorphic) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_004_heyting attribute_009_ex_max_of attribute_012_is_maximum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_004_heyting attribute_011_is_a_complement_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_004_heyting attribute_012_is_maximum_of) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_005_image attribute_014_lower_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_012_is_maximum_of attribute_014_lower_adjoint) (attribute_002_function attribute_003_galois attribute_009_ex_max_of attribute_012_is_maximum_of attribute_014_lower_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_013_is_minimum_of attribute_015_upper_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_014_lower_adjoint attribute_015_upper_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_005_image attribute_006_l1 attribute_007_l2) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic) (attribute_002_function attribute_003_galois attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_015_upper_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))
   (WMFCACover (attribute_002_function attribute_003_galois attribute_009_ex_max_of attribute_012_is_maximum_of attribute_014_lower_adjoint) (attribute_000_boolean attribute_001_connection attribute_002_function attribute_003_galois attribute_004_heyting attribute_005_image attribute_006_l1 attribute_007_l2 attribute_008_are_isomorphic attribute_009_ex_max_of attribute_010_ex_min_of attribute_011_is_a_complement_of attribute_012_is_maximum_of attribute_013_is_minimum_of attribute_014_lower_adjoint attribute_015_upper_adjoint))))
