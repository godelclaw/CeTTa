; Generated from a pinned public Formal Concept Analysis context.
; Source: https://github.com/EgorDudyrev/FCApy_benchmarks/blob/509f45a3b887e74258fb392fb7e2378e38cc9cf1/FCA_python_packages/performance_benchmark.py
; SHA-256: a8563b6967a3a3ce12d8aa61fe7b5d52b29f650dc2251bad2071ee7b8166352f
;
; The context is complete: all 10 x 10 cells are
; explicit observations.  Matrix zeroes are WMFalse, never WMMissing.  A single
; dependence group records that the cells belong to one FCApy controlled random matrix.

!(import! &self lib_wm_fca)

(= (wm-fca-random_10_10_0.9-objects)
   (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_004_g_4 object_005_g_5 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9))

(= (wm-fca-random_10_10_0.9-attributes)
   (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))

(= (wm-fca-random_10_10_0.9-state)
   (WMFCAState
     (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_004_g_4 object_005_g_5 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9)
     (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)
     (
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_000_m_0 WMTrue
  random_10_10_0.9-cell-000-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_001_m_1 WMTrue
  random_10_10_0.9-cell-000-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_002_m_2 WMTrue
  random_10_10_0.9-cell-000-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_003_m_3 WMTrue
  random_10_10_0.9-cell-000-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-000-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_005_m_5 WMTrue
  random_10_10_0.9-cell-000-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_006_m_6 WMTrue
  random_10_10_0.9-cell-000-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_007_m_7 WMTrue
  random_10_10_0.9-cell-000-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_008_m_8 WMTrue
  random_10_10_0.9-cell-000-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_000_g_0 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-000-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_000_m_0 WMTrue
  random_10_10_0.9-cell-001-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_001_m_1 WMTrue
  random_10_10_0.9-cell-001-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_002_m_2 WMTrue
  random_10_10_0.9-cell-001-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_003_m_3 WMTrue
  random_10_10_0.9-cell-001-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-001-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_005_m_5 WMTrue
  random_10_10_0.9-cell-001-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_006_m_6 WMTrue
  random_10_10_0.9-cell-001-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_007_m_7 WMTrue
  random_10_10_0.9-cell-001-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_008_m_8 WMTrue
  random_10_10_0.9-cell-001-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_001_g_1 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-001-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_000_m_0 WMTrue
  random_10_10_0.9-cell-002-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_001_m_1 WMTrue
  random_10_10_0.9-cell-002-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_002_m_2 WMTrue
  random_10_10_0.9-cell-002-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_003_m_3 WMTrue
  random_10_10_0.9-cell-002-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-002-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_005_m_5 WMTrue
  random_10_10_0.9-cell-002-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_006_m_6 WMFalse
  random_10_10_0.9-cell-002-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_007_m_7 WMTrue
  random_10_10_0.9-cell-002-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_008_m_8 WMTrue
  random_10_10_0.9-cell-002-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_002_g_2 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-002-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_000_m_0 WMTrue
  random_10_10_0.9-cell-003-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_001_m_1 WMTrue
  random_10_10_0.9-cell-003-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_002_m_2 WMTrue
  random_10_10_0.9-cell-003-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_003_m_3 WMTrue
  random_10_10_0.9-cell-003-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-003-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_005_m_5 WMTrue
  random_10_10_0.9-cell-003-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_006_m_6 WMTrue
  random_10_10_0.9-cell-003-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_007_m_7 WMTrue
  random_10_10_0.9-cell-003-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_008_m_8 WMTrue
  random_10_10_0.9-cell-003-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_003_g_3 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-003-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_000_m_0 WMFalse
  random_10_10_0.9-cell-004-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_001_m_1 WMFalse
  random_10_10_0.9-cell-004-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_002_m_2 WMFalse
  random_10_10_0.9-cell-004-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_003_m_3 WMTrue
  random_10_10_0.9-cell-004-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-004-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_005_m_5 WMFalse
  random_10_10_0.9-cell-004-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_006_m_6 WMTrue
  random_10_10_0.9-cell-004-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_007_m_7 WMFalse
  random_10_10_0.9-cell-004-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_008_m_8 WMFalse
  random_10_10_0.9-cell-004-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_004_g_4 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-004-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_000_m_0 WMTrue
  random_10_10_0.9-cell-005-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_001_m_1 WMTrue
  random_10_10_0.9-cell-005-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_002_m_2 WMTrue
  random_10_10_0.9-cell-005-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_003_m_3 WMTrue
  random_10_10_0.9-cell-005-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-005-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_005_m_5 WMTrue
  random_10_10_0.9-cell-005-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_006_m_6 WMFalse
  random_10_10_0.9-cell-005-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_007_m_7 WMTrue
  random_10_10_0.9-cell-005-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_008_m_8 WMTrue
  random_10_10_0.9-cell-005-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_005_g_5 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-005-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_000_m_0 WMTrue
  random_10_10_0.9-cell-006-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_001_m_1 WMFalse
  random_10_10_0.9-cell-006-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_002_m_2 WMTrue
  random_10_10_0.9-cell-006-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_003_m_3 WMTrue
  random_10_10_0.9-cell-006-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-006-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_005_m_5 WMTrue
  random_10_10_0.9-cell-006-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_006_m_6 WMTrue
  random_10_10_0.9-cell-006-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_007_m_7 WMTrue
  random_10_10_0.9-cell-006-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_008_m_8 WMTrue
  random_10_10_0.9-cell-006-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_006_g_6 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-006-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_000_m_0 WMTrue
  random_10_10_0.9-cell-007-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_001_m_1 WMTrue
  random_10_10_0.9-cell-007-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_002_m_2 WMTrue
  random_10_10_0.9-cell-007-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_003_m_3 WMFalse
  random_10_10_0.9-cell-007-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-007-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_005_m_5 WMTrue
  random_10_10_0.9-cell-007-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_006_m_6 WMTrue
  random_10_10_0.9-cell-007-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_007_m_7 WMTrue
  random_10_10_0.9-cell-007-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_008_m_8 WMTrue
  random_10_10_0.9-cell-007-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_007_g_7 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-007-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_000_m_0 WMTrue
  random_10_10_0.9-cell-008-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_001_m_1 WMTrue
  random_10_10_0.9-cell-008-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_002_m_2 WMTrue
  random_10_10_0.9-cell-008-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_003_m_3 WMTrue
  random_10_10_0.9-cell-008-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-008-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_005_m_5 WMTrue
  random_10_10_0.9-cell-008-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_006_m_6 WMTrue
  random_10_10_0.9-cell-008-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_007_m_7 WMTrue
  random_10_10_0.9-cell-008-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_008_m_8 WMTrue
  random_10_10_0.9-cell-008-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_008_g_8 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-008-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_000_m_0 WMTrue
  random_10_10_0.9-cell-009-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_001_m_1 WMTrue
  random_10_10_0.9-cell-009-001 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_002_m_2 WMTrue
  random_10_10_0.9-cell-009-002 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_003_m_3 WMTrue
  random_10_10_0.9-cell-009-003 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_004_m_4 WMTrue
  random_10_10_0.9-cell-009-004 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_005_m_5 WMTrue
  random_10_10_0.9-cell-009-005 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_006_m_6 WMTrue
  random_10_10_0.9-cell-009-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_007_m_7 WMTrue
  random_10_10_0.9-cell-009-007 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_008_m_8 WMTrue
  random_10_10_0.9-cell-009-008 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)
     (WMFCAObservation random_10_10_0.9 object_009_g_9 attribute_009_m_9 WMTrue
  random_10_10_0.9-cell-009-009 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix))))

(= (wm-fca-random_10_10_0.9-oracle-intents)
   (
   (attribute_004_m_4 attribute_009_m_9)
   (attribute_003_m_3 attribute_004_m_4 attribute_009_m_9)
   (attribute_004_m_4 attribute_006_m_6 attribute_009_m_9)
   (attribute_003_m_3 attribute_004_m_4 attribute_006_m_6 attribute_009_m_9)
   (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)
   (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)
   (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)
   (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)
   (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)
   (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)
   (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)
   (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)))

(= (wm-fca-random_10_10_0.9-oracle-concepts)
   (
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_004_g_4 object_005_g_5 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9) (attribute_004_m_4 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_004_g_4 object_005_g_5 object_006_g_6 object_008_g_8 object_009_g_9) (attribute_003_m_3 attribute_004_m_4 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_003_g_3 object_004_g_4 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9) (attribute_004_m_4 attribute_006_m_6 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_003_g_3 object_004_g_4 object_006_g_6 object_008_g_8 object_009_g_9) (attribute_003_m_3 attribute_004_m_4 attribute_006_m_6 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_005_g_5 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9) (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_005_g_5 object_007_g_7 object_008_g_8 object_009_g_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_005_g_5 object_006_g_6 object_008_g_8 object_009_g_9) (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_003_g_3 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9) (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_005_g_5 object_008_g_8 object_009_g_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_003_g_3 object_007_g_7 object_008_g_8 object_009_g_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_003_g_3 object_006_g_6 object_008_g_8 object_009_g_9) (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCAConcept (object_000_g_0 object_001_g_1 object_003_g_3 object_008_g_8 object_009_g_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))))

(= (wm-fca-random_10_10_0.9-oracle-basis)
   (
   (WMFCAImplication () (attribute_004_m_4 attribute_009_m_9))
   (WMFCAImplication (attribute_000_m_0 attribute_004_m_4 attribute_009_m_9) (attribute_002_m_2 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8))
   (WMFCAImplication (attribute_001_m_1 attribute_004_m_4 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8))
   (WMFCAImplication (attribute_002_m_2 attribute_004_m_4 attribute_009_m_9) (attribute_000_m_0 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8))
   (WMFCAImplication (attribute_004_m_4 attribute_005_m_5 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_007_m_7 attribute_008_m_8))
   (WMFCAImplication (attribute_004_m_4 attribute_007_m_7 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_005_m_5 attribute_008_m_8))
   (WMFCAImplication (attribute_004_m_4 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_005_m_5 attribute_007_m_7))))

; Cover direction follows intent inclusion: general intent -> specific intent.
(= (wm-fca-random_10_10_0.9-oracle-covers)
   (
   (WMFCACover (attribute_004_m_4 attribute_009_m_9) (attribute_003_m_3 attribute_004_m_4 attribute_009_m_9))
   (WMFCACover (attribute_004_m_4 attribute_009_m_9) (attribute_004_m_4 attribute_006_m_6 attribute_009_m_9))
   (WMFCACover (attribute_004_m_4 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_003_m_3 attribute_004_m_4 attribute_009_m_9) (attribute_003_m_3 attribute_004_m_4 attribute_006_m_6 attribute_009_m_9))
   (WMFCACover (attribute_003_m_3 attribute_004_m_4 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_004_m_4 attribute_006_m_6 attribute_009_m_9) (attribute_003_m_3 attribute_004_m_4 attribute_006_m_6 attribute_009_m_9))
   (WMFCACover (attribute_004_m_4 attribute_006_m_6 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_003_m_3 attribute_004_m_4 attribute_006_m_6 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
   (WMFCACover (attribute_000_m_0 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))))
