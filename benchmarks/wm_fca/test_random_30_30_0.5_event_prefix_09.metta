!(import! &self ./random_30_30_0.5_event_context.metta)

; Prefix 9: incremental native state is checked against values
; freshly recomputed by the independent Python oracle from surviving evidence.

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_30_30_0.5-event-state-09))
   901)
!(assertEqual
   (let $events (eval (wm-fca-state-events (wm-fca-random_30_30_0.5-event-state-09)))
     (size-atom $events))
   9)
!(assertEqual
   (wm-fca-cell-status (wm-fca-random_30_30_0.5-event-state-09) random_30_30_0.5 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-explain-cell (wm-fca-random_30_30_0.5-event-state-09) random_30_30_0.5 object_000_g_0 attribute_000_m_0)
   (
   (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_000_m_0 WMTrue (WMFCAPackedStamp random_30_30_0.5 object_000_g_0 attribute_000_m_0) fcapy-controlled-random-509f45a3 random_30_30_0.5-generated-matrix)
   (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_000_m_0 WMTrue wm-fca-event-positive-1 wm-fca-event-source-1 wm-fca-event-group-1)))
!(assertEqual
   (wm-fca-cell-status (wm-fca-random_30_30_0.5-event-state-09) random_30_30_0.5 object_000_g_0 attribute_002_m_2)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell (wm-fca-random_30_30_0.5-event-state-09) random_30_30_0.5 object_000_g_0 attribute_002_m_2)
   (
   (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_002_m_2 WMFalse (WMFCAPackedStamp random_30_30_0.5 object_000_g_0 attribute_002_m_2) fcapy-controlled-random-509f45a3 random_30_30_0.5-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status (wm-fca-random_30_30_0.5-event-state-09) random_30_30_0.5-foreign-context object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (wm-fca-explain-cell (wm-fca-random_30_30_0.5-event-state-09) random_30_30_0.5-foreign-context object_000_g_0 attribute_000_m_0)
   ())
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-random_30_30_0.5-event-state-09)
     random_30_30_0.5
     WMFCAExactStatusGate
     (wm-fca-random_30_30_0.5-event-query-candidates))
   (
     (WMFCABatchQueryResult () (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_004_g_4 object_005_g_5 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9 object_010_g_10 object_011_g_11 object_012_g_12 object_013_g_13 object_014_g_14 object_015_g_15 object_016_g_16 object_017_g_17 object_018_g_18 object_019_g_19 object_020_g_20 object_021_g_21 object_022_g_22 object_023_g_23 object_024_g_24 object_025_g_25 object_026_g_26 object_027_g_27 object_028_g_28 object_029_g_29) ())
     (WMFCABatchQueryResult (attribute_000_m_0) (object_000_g_0 object_002_g_2 object_003_g_3 object_004_g_4 object_008_g_8 object_011_g_11 object_012_g_12 object_014_g_14 object_016_g_16 object_018_g_18 object_019_g_19 object_021_g_21 object_022_g_22 object_026_g_26 object_028_g_28) (attribute_000_m_0))
     (WMFCABatchQueryResult (attribute_002_m_2) (object_002_g_2 object_003_g_3 object_006_g_6 object_010_g_10 object_011_g_11 object_013_g_13 object_014_g_14 object_016_g_16 object_017_g_17 object_020_g_20 object_023_g_23 object_025_g_25 object_027_g_27) (attribute_002_m_2))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_002_m_2) (object_002_g_2 object_003_g_3 object_011_g_11 object_014_g_14 object_016_g_16) (attribute_000_m_0 attribute_002_m_2 attribute_018_m_18))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_001_m_1) (object_000_g_0 object_004_g_4 object_011_g_11 object_012_g_12 object_014_g_14 object_018_g_18 object_019_g_19 object_021_g_21 object_028_g_28) (attribute_000_m_0 attribute_001_m_1 attribute_022_m_22))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3) (object_014_g_14) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_008_m_8 attribute_009_m_9 attribute_012_m_12 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_022_m_22 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_029_m_29) (object_001_g_1 object_002_g_2 object_003_g_3 object_005_g_5 object_006_g_6 object_007_g_7 object_009_g_9 object_010_g_10 object_011_g_11 object_012_g_12 object_014_g_14 object_017_g_17 object_020_g_20 object_026_g_26 object_029_g_29) (attribute_029_m_29))))
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-random_30_30_0.5-event-state-09)
     random_30_30_0.5
     (WMFCAPositiveObservationThreshold 2)
     (wm-fca-random_30_30_0.5-event-query-candidates))
   (
     (WMFCABatchQueryResult () (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_004_g_4 object_005_g_5 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9 object_010_g_10 object_011_g_11 object_012_g_12 object_013_g_13 object_014_g_14 object_015_g_15 object_016_g_16 object_017_g_17 object_018_g_18 object_019_g_19 object_020_g_20 object_021_g_21 object_022_g_22 object_023_g_23 object_024_g_24 object_025_g_25 object_026_g_26 object_027_g_27 object_028_g_28 object_029_g_29) ())
     (WMFCABatchQueryResult (attribute_000_m_0) (object_000_g_0) (attribute_000_m_0))
     (WMFCABatchQueryResult (attribute_002_m_2) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_002_m_2) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_001_m_1) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_029_m_29) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))))
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-random_30_30_0.5-event-state-09)
     random_30_30_0.5
     (WMFCAPositiveSourceThreshold 2)
     (wm-fca-random_30_30_0.5-event-query-candidates))
   (
     (WMFCABatchQueryResult () (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_004_g_4 object_005_g_5 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9 object_010_g_10 object_011_g_11 object_012_g_12 object_013_g_13 object_014_g_14 object_015_g_15 object_016_g_16 object_017_g_17 object_018_g_18 object_019_g_19 object_020_g_20 object_021_g_21 object_022_g_22 object_023_g_23 object_024_g_24 object_025_g_25 object_026_g_26 object_027_g_27 object_028_g_28 object_029_g_29) ())
     (WMFCABatchQueryResult (attribute_000_m_0) (object_000_g_0) (attribute_000_m_0))
     (WMFCABatchQueryResult (attribute_002_m_2) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_002_m_2) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_001_m_1) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_029_m_29) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))))
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-random_30_30_0.5-event-state-09)
     random_30_30_0.5
     (WMFCAPositiveDependenceGroupThreshold 2)
     (wm-fca-random_30_30_0.5-event-query-candidates))
   (
     (WMFCABatchQueryResult () (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_004_g_4 object_005_g_5 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9 object_010_g_10 object_011_g_11 object_012_g_12 object_013_g_13 object_014_g_14 object_015_g_15 object_016_g_16 object_017_g_17 object_018_g_18 object_019_g_19 object_020_g_20 object_021_g_21 object_022_g_22 object_023_g_23 object_024_g_24 object_025_g_25 object_026_g_26 object_027_g_27 object_028_g_28 object_029_g_29) ())
     (WMFCABatchQueryResult (attribute_000_m_0) (object_000_g_0) (attribute_000_m_0))
     (WMFCABatchQueryResult (attribute_002_m_2) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_002_m_2) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_001_m_1) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))
     (WMFCABatchQueryResult (attribute_029_m_29) () (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29))))
