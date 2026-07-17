; Generated from a pinned public Formal Concept Analysis context.
; Source: https://github.com/fcatools/contexts/blob/9306d256c8a212ffa0c60a52f883a516d8b87b58/contexts/binary_relations_en.cxt
; SHA-256: 165a56063f0f3487382a5835e5cd6414fe99e88e6602f22350817caff963108d
;
; The context is complete: all 14 x 9 cells are
; explicit observations.  Matrix zeroes are WMFalse, never WMMissing.  A single
; dependence group records that the cells belong to one published matrix.

!(import! &self lib_wm_fca)

(= (wm-fca-binary_relations-objects)
   (object_000_object_1 object_001_object_2 object_002_object_3 object_003_object_4 object_004_object_5 object_005_object_6 object_006_object_7 object_007_object_8 object_008_object_9 object_009_object_10 object_010_object_11 object_011_object_12 object_012_object_13 object_013_object_14))

(= (wm-fca-binary_relations-attributes)
   (attribute_000_reflexive attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))

(= (wm-fca-binary_relations-state)
   (WMFCAState
     (object_000_object_1 object_001_object_2 object_002_object_3 object_003_object_4 object_004_object_5 object_005_object_6 object_006_object_7 object_007_object_8 object_008_object_9 object_009_object_10 object_010_object_11 object_011_object_12 object_012_object_13 object_013_object_14)
     (attribute_000_reflexive attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex)
     (
     (WMFCAObservation binary_relations object_000_object_1 attribute_000_reflexive WMFalse
  binary_relations-cell-000-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_000_object_1 attribute_001_irreflexive WMTrue
  binary_relations-cell-000-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_000_object_1 attribute_002_symmetric WMTrue
  binary_relations-cell-000-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_000_object_1 attribute_003_asymmetric WMTrue
  binary_relations-cell-000-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_000_object_1 attribute_004_antisymmetric WMTrue
  binary_relations-cell-000-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_000_object_1 attribute_005_transitive WMTrue
  binary_relations-cell-000-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_000_object_1 attribute_006_negatively_transitive WMTrue
  binary_relations-cell-000-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_000_object_1 attribute_007_connex WMTrue
  binary_relations-cell-000-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_000_object_1 attribute_008_strictly_connex WMFalse
  binary_relations-cell-000-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_001_object_2 attribute_000_reflexive WMTrue
  binary_relations-cell-001-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_001_object_2 attribute_001_irreflexive WMFalse
  binary_relations-cell-001-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_001_object_2 attribute_002_symmetric WMTrue
  binary_relations-cell-001-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_001_object_2 attribute_003_asymmetric WMFalse
  binary_relations-cell-001-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_001_object_2 attribute_004_antisymmetric WMTrue
  binary_relations-cell-001-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_001_object_2 attribute_005_transitive WMTrue
  binary_relations-cell-001-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_001_object_2 attribute_006_negatively_transitive WMTrue
  binary_relations-cell-001-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_001_object_2 attribute_007_connex WMTrue
  binary_relations-cell-001-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_001_object_2 attribute_008_strictly_connex WMTrue
  binary_relations-cell-001-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_002_object_3 attribute_000_reflexive WMFalse
  binary_relations-cell-002-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_002_object_3 attribute_001_irreflexive WMTrue
  binary_relations-cell-002-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_002_object_3 attribute_002_symmetric WMTrue
  binary_relations-cell-002-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_002_object_3 attribute_003_asymmetric WMTrue
  binary_relations-cell-002-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_002_object_3 attribute_004_antisymmetric WMTrue
  binary_relations-cell-002-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_002_object_3 attribute_005_transitive WMTrue
  binary_relations-cell-002-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_002_object_3 attribute_006_negatively_transitive WMTrue
  binary_relations-cell-002-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_002_object_3 attribute_007_connex WMFalse
  binary_relations-cell-002-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_002_object_3 attribute_008_strictly_connex WMFalse
  binary_relations-cell-002-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_003_object_4 attribute_000_reflexive WMTrue
  binary_relations-cell-003-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_003_object_4 attribute_001_irreflexive WMFalse
  binary_relations-cell-003-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_003_object_4 attribute_002_symmetric WMTrue
  binary_relations-cell-003-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_003_object_4 attribute_003_asymmetric WMFalse
  binary_relations-cell-003-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_003_object_4 attribute_004_antisymmetric WMTrue
  binary_relations-cell-003-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_003_object_4 attribute_005_transitive WMTrue
  binary_relations-cell-003-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_003_object_4 attribute_006_negatively_transitive WMFalse
  binary_relations-cell-003-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_003_object_4 attribute_007_connex WMFalse
  binary_relations-cell-003-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_003_object_4 attribute_008_strictly_connex WMFalse
  binary_relations-cell-003-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_004_object_5 attribute_000_reflexive WMTrue
  binary_relations-cell-004-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_004_object_5 attribute_001_irreflexive WMFalse
  binary_relations-cell-004-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_004_object_5 attribute_002_symmetric WMFalse
  binary_relations-cell-004-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_004_object_5 attribute_003_asymmetric WMFalse
  binary_relations-cell-004-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_004_object_5 attribute_004_antisymmetric WMTrue
  binary_relations-cell-004-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_004_object_5 attribute_005_transitive WMTrue
  binary_relations-cell-004-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_004_object_5 attribute_006_negatively_transitive WMTrue
  binary_relations-cell-004-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_004_object_5 attribute_007_connex WMTrue
  binary_relations-cell-004-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_004_object_5 attribute_008_strictly_connex WMTrue
  binary_relations-cell-004-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_005_object_6 attribute_000_reflexive WMFalse
  binary_relations-cell-005-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_005_object_6 attribute_001_irreflexive WMTrue
  binary_relations-cell-005-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_005_object_6 attribute_002_symmetric WMFalse
  binary_relations-cell-005-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_005_object_6 attribute_003_asymmetric WMTrue
  binary_relations-cell-005-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_005_object_6 attribute_004_antisymmetric WMTrue
  binary_relations-cell-005-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_005_object_6 attribute_005_transitive WMTrue
  binary_relations-cell-005-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_005_object_6 attribute_006_negatively_transitive WMTrue
  binary_relations-cell-005-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_005_object_6 attribute_007_connex WMTrue
  binary_relations-cell-005-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_005_object_6 attribute_008_strictly_connex WMFalse
  binary_relations-cell-005-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_006_object_7 attribute_000_reflexive WMFalse
  binary_relations-cell-006-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_006_object_7 attribute_001_irreflexive WMTrue
  binary_relations-cell-006-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_006_object_7 attribute_002_symmetric WMTrue
  binary_relations-cell-006-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_006_object_7 attribute_003_asymmetric WMFalse
  binary_relations-cell-006-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_006_object_7 attribute_004_antisymmetric WMFalse
  binary_relations-cell-006-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_006_object_7 attribute_005_transitive WMFalse
  binary_relations-cell-006-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_006_object_7 attribute_006_negatively_transitive WMTrue
  binary_relations-cell-006-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_006_object_7 attribute_007_connex WMTrue
  binary_relations-cell-006-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_006_object_7 attribute_008_strictly_connex WMFalse
  binary_relations-cell-006-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_007_object_8 attribute_000_reflexive WMTrue
  binary_relations-cell-007-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_007_object_8 attribute_001_irreflexive WMFalse
  binary_relations-cell-007-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_007_object_8 attribute_002_symmetric WMTrue
  binary_relations-cell-007-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_007_object_8 attribute_003_asymmetric WMFalse
  binary_relations-cell-007-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_007_object_8 attribute_004_antisymmetric WMFalse
  binary_relations-cell-007-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_007_object_8 attribute_005_transitive WMTrue
  binary_relations-cell-007-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_007_object_8 attribute_006_negatively_transitive WMTrue
  binary_relations-cell-007-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_007_object_8 attribute_007_connex WMTrue
  binary_relations-cell-007-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_007_object_8 attribute_008_strictly_connex WMTrue
  binary_relations-cell-007-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_008_object_9 attribute_000_reflexive WMTrue
  binary_relations-cell-008-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_008_object_9 attribute_001_irreflexive WMFalse
  binary_relations-cell-008-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_008_object_9 attribute_002_symmetric WMFalse
  binary_relations-cell-008-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_008_object_9 attribute_003_asymmetric WMFalse
  binary_relations-cell-008-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_008_object_9 attribute_004_antisymmetric WMTrue
  binary_relations-cell-008-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_008_object_9 attribute_005_transitive WMFalse
  binary_relations-cell-008-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_008_object_9 attribute_006_negatively_transitive WMFalse
  binary_relations-cell-008-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_008_object_9 attribute_007_connex WMTrue
  binary_relations-cell-008-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_008_object_9 attribute_008_strictly_connex WMTrue
  binary_relations-cell-008-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_009_object_10 attribute_000_reflexive WMFalse
  binary_relations-cell-009-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_009_object_10 attribute_001_irreflexive WMTrue
  binary_relations-cell-009-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_009_object_10 attribute_002_symmetric WMFalse
  binary_relations-cell-009-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_009_object_10 attribute_003_asymmetric WMTrue
  binary_relations-cell-009-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_009_object_10 attribute_004_antisymmetric WMTrue
  binary_relations-cell-009-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_009_object_10 attribute_005_transitive WMFalse
  binary_relations-cell-009-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_009_object_10 attribute_006_negatively_transitive WMFalse
  binary_relations-cell-009-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_009_object_10 attribute_007_connex WMTrue
  binary_relations-cell-009-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_009_object_10 attribute_008_strictly_connex WMFalse
  binary_relations-cell-009-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_010_object_11 attribute_000_reflexive WMFalse
  binary_relations-cell-010-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_010_object_11 attribute_001_irreflexive WMTrue
  binary_relations-cell-010-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_010_object_11 attribute_002_symmetric WMFalse
  binary_relations-cell-010-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_010_object_11 attribute_003_asymmetric WMTrue
  binary_relations-cell-010-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_010_object_11 attribute_004_antisymmetric WMTrue
  binary_relations-cell-010-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_010_object_11 attribute_005_transitive WMTrue
  binary_relations-cell-010-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_010_object_11 attribute_006_negatively_transitive WMFalse
  binary_relations-cell-010-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_010_object_11 attribute_007_connex WMFalse
  binary_relations-cell-010-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_010_object_11 attribute_008_strictly_connex WMFalse
  binary_relations-cell-010-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_011_object_12 attribute_000_reflexive WMFalse
  binary_relations-cell-011-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_011_object_12 attribute_001_irreflexive WMTrue
  binary_relations-cell-011-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_011_object_12 attribute_002_symmetric WMTrue
  binary_relations-cell-011-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_011_object_12 attribute_003_asymmetric WMFalse
  binary_relations-cell-011-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_011_object_12 attribute_004_antisymmetric WMFalse
  binary_relations-cell-011-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_011_object_12 attribute_005_transitive WMFalse
  binary_relations-cell-011-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_011_object_12 attribute_006_negatively_transitive WMFalse
  binary_relations-cell-011-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_011_object_12 attribute_007_connex WMFalse
  binary_relations-cell-011-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_011_object_12 attribute_008_strictly_connex WMFalse
  binary_relations-cell-011-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_012_object_13 attribute_000_reflexive WMTrue
  binary_relations-cell-012-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_012_object_13 attribute_001_irreflexive WMFalse
  binary_relations-cell-012-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_012_object_13 attribute_002_symmetric WMFalse
  binary_relations-cell-012-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_012_object_13 attribute_003_asymmetric WMFalse
  binary_relations-cell-012-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_012_object_13 attribute_004_antisymmetric WMFalse
  binary_relations-cell-012-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_012_object_13 attribute_005_transitive WMFalse
  binary_relations-cell-012-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_012_object_13 attribute_006_negatively_transitive WMTrue
  binary_relations-cell-012-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_012_object_13 attribute_007_connex WMTrue
  binary_relations-cell-012-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_012_object_13 attribute_008_strictly_connex WMTrue
  binary_relations-cell-012-008 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_013_object_14 attribute_000_reflexive WMTrue
  binary_relations-cell-013-000 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_013_object_14 attribute_001_irreflexive WMFalse
  binary_relations-cell-013-001 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_013_object_14 attribute_002_symmetric WMTrue
  binary_relations-cell-013-002 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_013_object_14 attribute_003_asymmetric WMFalse
  binary_relations-cell-013-003 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_013_object_14 attribute_004_antisymmetric WMFalse
  binary_relations-cell-013-004 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_013_object_14 attribute_005_transitive WMFalse
  binary_relations-cell-013-005 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_013_object_14 attribute_006_negatively_transitive WMFalse
  binary_relations-cell-013-006 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_013_object_14 attribute_007_connex WMFalse
  binary_relations-cell-013-007 fcatools-contexts-9306d256 binary_relations-published-matrix)
     (WMFCAObservation binary_relations object_013_object_14 attribute_008_strictly_connex WMFalse
  binary_relations-cell-013-008 fcatools-contexts-9306d256 binary_relations-published-matrix))))

(= (wm-fca-binary_relations-oracle-intents)
   (
   ()
   (attribute_000_reflexive)
   (attribute_001_irreflexive)
   (attribute_002_symmetric)
   (attribute_004_antisymmetric)
   (attribute_005_transitive)
   (attribute_006_negatively_transitive)
   (attribute_007_connex)
   (attribute_000_reflexive attribute_002_symmetric)
   (attribute_000_reflexive attribute_004_antisymmetric)
   (attribute_000_reflexive attribute_005_transitive)
   (attribute_001_irreflexive attribute_002_symmetric)
   (attribute_001_irreflexive attribute_006_negatively_transitive)
   (attribute_001_irreflexive attribute_007_connex)
   (attribute_002_symmetric attribute_005_transitive)
   (attribute_002_symmetric attribute_006_negatively_transitive)
   (attribute_004_antisymmetric attribute_005_transitive)
   (attribute_004_antisymmetric attribute_007_connex)
   (attribute_005_transitive attribute_006_negatively_transitive)
   (attribute_006_negatively_transitive attribute_007_connex)
   (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive)
   (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive)
   (attribute_000_reflexive attribute_007_connex attribute_008_strictly_connex)
   (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive)
   (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric)
   (attribute_001_irreflexive attribute_006_negatively_transitive attribute_007_connex)
   (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive)
   (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive)
   (attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex)
   (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive)
   (attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex)
   (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive)
   (attribute_000_reflexive attribute_004_antisymmetric attribute_007_connex attribute_008_strictly_connex)
   (attribute_000_reflexive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex)
   (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex)
   (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive)
   (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_007_connex)
   (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive)
   (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex)
   (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex)
   (attribute_000_reflexive attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex)
   (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive)
   (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex)
   (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex)
   (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex)
   (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive)
   (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex)
   (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex)
   (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex)
   (attribute_000_reflexive attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex)))

(= (wm-fca-binary_relations-oracle-concepts)
   (
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_003_object_4 object_004_object_5 object_005_object_6 object_006_object_7 object_007_object_8 object_008_object_9 object_009_object_10 object_010_object_11 object_011_object_12 object_012_object_13 object_013_object_14) ())
   (WMFCAConcept (object_001_object_2 object_003_object_4 object_004_object_5 object_007_object_8 object_008_object_9 object_012_object_13 object_013_object_14) (attribute_000_reflexive))
   (WMFCAConcept (object_000_object_1 object_002_object_3 object_005_object_6 object_006_object_7 object_009_object_10 object_010_object_11 object_011_object_12) (attribute_001_irreflexive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_003_object_4 object_006_object_7 object_007_object_8 object_011_object_12 object_013_object_14) (attribute_002_symmetric))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_003_object_4 object_004_object_5 object_005_object_6 object_008_object_9 object_009_object_10 object_010_object_11) (attribute_004_antisymmetric))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_003_object_4 object_004_object_5 object_005_object_6 object_007_object_8 object_010_object_11) (attribute_005_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_004_object_5 object_005_object_6 object_006_object_7 object_007_object_8 object_012_object_13) (attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_004_object_5 object_005_object_6 object_006_object_7 object_007_object_8 object_008_object_9 object_009_object_10 object_012_object_13) (attribute_007_connex))
   (WMFCAConcept (object_001_object_2 object_003_object_4 object_007_object_8 object_013_object_14) (attribute_000_reflexive attribute_002_symmetric))
   (WMFCAConcept (object_001_object_2 object_003_object_4 object_004_object_5 object_008_object_9) (attribute_000_reflexive attribute_004_antisymmetric))
   (WMFCAConcept (object_001_object_2 object_003_object_4 object_004_object_5 object_007_object_8) (attribute_000_reflexive attribute_005_transitive))
   (WMFCAConcept (object_000_object_1 object_002_object_3 object_006_object_7 object_011_object_12) (attribute_001_irreflexive attribute_002_symmetric))
   (WMFCAConcept (object_000_object_1 object_002_object_3 object_005_object_6 object_006_object_7) (attribute_001_irreflexive attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_005_object_6 object_006_object_7 object_009_object_10) (attribute_001_irreflexive attribute_007_connex))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_003_object_4 object_007_object_8) (attribute_002_symmetric attribute_005_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_006_object_7 object_007_object_8) (attribute_002_symmetric attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_003_object_4 object_004_object_5 object_005_object_6 object_010_object_11) (attribute_004_antisymmetric attribute_005_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_004_object_5 object_005_object_6 object_008_object_9 object_009_object_10) (attribute_004_antisymmetric attribute_007_connex))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_004_object_5 object_005_object_6 object_007_object_8) (attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_004_object_5 object_005_object_6 object_006_object_7 object_007_object_8 object_012_object_13) (attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept (object_001_object_2 object_003_object_4 object_007_object_8) (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive))
   (WMFCAConcept (object_001_object_2 object_003_object_4 object_004_object_5) (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive))
   (WMFCAConcept (object_001_object_2 object_004_object_5 object_007_object_8 object_008_object_9 object_012_object_13) (attribute_000_reflexive attribute_007_connex attribute_008_strictly_connex))
   (WMFCAConcept (object_000_object_1 object_002_object_3 object_006_object_7) (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_002_object_3 object_005_object_6 object_009_object_10 object_010_object_11) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric))
   (WMFCAConcept (object_000_object_1 object_005_object_6 object_006_object_7) (attribute_001_irreflexive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_003_object_4) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_007_object_8) (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_006_object_7 object_007_object_8) (attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3 object_004_object_5 object_005_object_6) (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_004_object_5 object_005_object_6 object_007_object_8) (attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept (object_001_object_2 object_003_object_4) (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCAConcept (object_001_object_2 object_004_object_5 object_008_object_9) (attribute_000_reflexive attribute_004_antisymmetric attribute_007_connex attribute_008_strictly_connex))
   (WMFCAConcept (object_001_object_2 object_004_object_5 object_007_object_8 object_012_object_13) (attribute_000_reflexive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCAConcept (object_000_object_1 object_006_object_7) (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept (object_000_object_1 object_002_object_3 object_005_object_6 object_010_object_11) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCAConcept (object_000_object_1 object_005_object_6 object_009_object_10) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_007_connex))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_002_object_3) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_007_object_8) (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept (object_000_object_1 object_001_object_2 object_004_object_5 object_005_object_6) (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept (object_001_object_2 object_004_object_5 object_007_object_8) (attribute_000_reflexive attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCAConcept (object_000_object_1 object_002_object_3 object_005_object_6) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_001_object_2) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept (object_001_object_2 object_007_object_8) (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCAConcept (object_001_object_2 object_004_object_5) (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCAConcept (object_000_object_1 object_002_object_3) (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCAConcept (object_000_object_1 object_005_object_6) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept (object_001_object_2) (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCAConcept (object_000_object_1) (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCAConcept () (attribute_000_reflexive attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))))

(= (wm-fca-binary_relations-oracle-basis)
   (
   (WMFCAImplication (attribute_003_asymmetric) (attribute_001_irreflexive attribute_004_antisymmetric))
   (WMFCAImplication (attribute_008_strictly_connex) (attribute_000_reflexive attribute_007_connex))
   (WMFCAImplication (attribute_000_reflexive attribute_001_irreflexive) (attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCAImplication (attribute_000_reflexive attribute_006_negatively_transitive) (attribute_007_connex attribute_008_strictly_connex))
   (WMFCAImplication (attribute_000_reflexive attribute_007_connex) (attribute_008_strictly_connex))
   (WMFCAImplication (attribute_001_irreflexive attribute_004_antisymmetric) (attribute_003_asymmetric))
   (WMFCAImplication (attribute_001_irreflexive attribute_005_transitive) (attribute_003_asymmetric attribute_004_antisymmetric))
   (WMFCAImplication (attribute_002_symmetric attribute_004_antisymmetric) (attribute_005_transitive))
   (WMFCAImplication (attribute_002_symmetric attribute_007_connex) (attribute_006_negatively_transitive))
   (WMFCAImplication (attribute_004_antisymmetric attribute_006_negatively_transitive) (attribute_005_transitive))
   (WMFCAImplication (attribute_005_transitive attribute_007_connex) (attribute_006_negatively_transitive))
   (WMFCAImplication (attribute_000_reflexive attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex) (attribute_005_transitive))
   (WMFCAImplication (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive) (attribute_006_negatively_transitive))))

; Cover direction follows intent inclusion: general intent -> specific intent.
(= (wm-fca-binary_relations-oracle-covers)
   (
   (WMFCACover () (attribute_000_reflexive))
   (WMFCACover () (attribute_001_irreflexive))
   (WMFCACover () (attribute_002_symmetric))
   (WMFCACover () (attribute_004_antisymmetric))
   (WMFCACover () (attribute_005_transitive))
   (WMFCACover () (attribute_006_negatively_transitive))
   (WMFCACover () (attribute_007_connex))
   (WMFCACover (attribute_000_reflexive) (attribute_000_reflexive attribute_002_symmetric))
   (WMFCACover (attribute_000_reflexive) (attribute_000_reflexive attribute_004_antisymmetric))
   (WMFCACover (attribute_000_reflexive) (attribute_000_reflexive attribute_005_transitive))
   (WMFCACover (attribute_000_reflexive) (attribute_000_reflexive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_001_irreflexive) (attribute_001_irreflexive attribute_002_symmetric))
   (WMFCACover (attribute_001_irreflexive) (attribute_001_irreflexive attribute_006_negatively_transitive))
   (WMFCACover (attribute_001_irreflexive) (attribute_001_irreflexive attribute_007_connex))
   (WMFCACover (attribute_001_irreflexive) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric))
   (WMFCACover (attribute_002_symmetric) (attribute_000_reflexive attribute_002_symmetric))
   (WMFCACover (attribute_002_symmetric) (attribute_001_irreflexive attribute_002_symmetric))
   (WMFCACover (attribute_002_symmetric) (attribute_002_symmetric attribute_005_transitive))
   (WMFCACover (attribute_002_symmetric) (attribute_002_symmetric attribute_006_negatively_transitive))
   (WMFCACover (attribute_004_antisymmetric) (attribute_000_reflexive attribute_004_antisymmetric))
   (WMFCACover (attribute_004_antisymmetric) (attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_004_antisymmetric) (attribute_004_antisymmetric attribute_007_connex))
   (WMFCACover (attribute_004_antisymmetric) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric))
   (WMFCACover (attribute_005_transitive) (attribute_000_reflexive attribute_005_transitive))
   (WMFCACover (attribute_005_transitive) (attribute_002_symmetric attribute_005_transitive))
   (WMFCACover (attribute_005_transitive) (attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_005_transitive) (attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_006_negatively_transitive))
   (WMFCACover (attribute_006_negatively_transitive) (attribute_002_symmetric attribute_006_negatively_transitive))
   (WMFCACover (attribute_006_negatively_transitive) (attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_006_negatively_transitive) (attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_007_connex) (attribute_001_irreflexive attribute_007_connex))
   (WMFCACover (attribute_007_connex) (attribute_004_antisymmetric attribute_007_connex))
   (WMFCACover (attribute_007_connex) (attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_007_connex) (attribute_000_reflexive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_002_symmetric) (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive))
   (WMFCACover (attribute_000_reflexive attribute_004_antisymmetric) (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_000_reflexive attribute_004_antisymmetric) (attribute_000_reflexive attribute_004_antisymmetric attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_005_transitive) (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive))
   (WMFCACover (attribute_000_reflexive attribute_005_transitive) (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_000_reflexive attribute_005_transitive) (attribute_000_reflexive attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_001_irreflexive attribute_002_symmetric) (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive))
   (WMFCACover (attribute_001_irreflexive attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive))
   (WMFCACover (attribute_001_irreflexive attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_001_irreflexive attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_001_irreflexive attribute_007_connex) (attribute_001_irreflexive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_001_irreflexive attribute_007_connex) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_007_connex))
   (WMFCACover (attribute_002_symmetric attribute_005_transitive) (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive))
   (WMFCACover (attribute_002_symmetric attribute_005_transitive) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_002_symmetric attribute_005_transitive) (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_002_symmetric attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive))
   (WMFCACover (attribute_002_symmetric attribute_006_negatively_transitive) (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_002_symmetric attribute_006_negatively_transitive) (attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive) (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive) (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_004_antisymmetric attribute_007_connex) (attribute_000_reflexive attribute_004_antisymmetric attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_004_antisymmetric attribute_007_connex) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_007_connex))
   (WMFCACover (attribute_004_antisymmetric attribute_007_connex) (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_005_transitive attribute_006_negatively_transitive) (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_005_transitive attribute_006_negatively_transitive) (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_005_transitive attribute_006_negatively_transitive) (attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_006_negatively_transitive attribute_007_connex) (attribute_001_irreflexive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_006_negatively_transitive attribute_007_connex) (attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_006_negatively_transitive attribute_007_connex) (attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_006_negatively_transitive attribute_007_connex) (attribute_000_reflexive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive) (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive) (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive) (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive) (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_007_connex attribute_008_strictly_connex) (attribute_000_reflexive attribute_004_antisymmetric attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_007_connex attribute_008_strictly_connex) (attribute_000_reflexive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_007_connex))
   (WMFCACover (attribute_001_irreflexive attribute_006_negatively_transitive attribute_007_connex) (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_001_irreflexive attribute_006_negatively_transitive attribute_007_connex) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive) (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive))
   (WMFCACover (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex) (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex) (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_000_reflexive attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive) (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_004_antisymmetric attribute_007_connex attribute_008_strictly_connex) (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex) (attribute_000_reflexive attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_001_irreflexive attribute_002_symmetric attribute_006_negatively_transitive attribute_007_connex) (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_007_connex) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_000_reflexive attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex) (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex) (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive))
   (WMFCACover (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_000_reflexive attribute_002_symmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex) (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_000_reflexive attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex) (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive) (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex))
   (WMFCACover (attribute_000_reflexive attribute_002_symmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex) (attribute_000_reflexive attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))
   (WMFCACover (attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex) (attribute_000_reflexive attribute_001_irreflexive attribute_002_symmetric attribute_003_asymmetric attribute_004_antisymmetric attribute_005_transitive attribute_006_negatively_transitive attribute_007_connex attribute_008_strictly_connex))))
