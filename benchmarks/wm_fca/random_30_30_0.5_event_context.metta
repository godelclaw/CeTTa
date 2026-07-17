; Generated from an independent, receipt-backed WM event oracle.
; Context SHA-256: e741867939255b01b67d043ee9f35adda630a18eae1dd430a89aeaf9fb813fce
; Protocol SHA-256: 387a1775c10db4cc043b3b63dbda76ff58fbf2f28462cfe77ecd73d244909668
;
; Each state is immutable.  The runtime stores events newest-first and replays
; them oldest-first; no interpreted matrix recursion or lattice enumeration is
; used by this lifecycle fixture.

!(import! &self ./random_30_30_0.5_context.metta)

(= (wm-fca-random_30_30_0.5-event-state-00)
   (wm-fca-random_30_30_0.5-state))
(= (wm-fca-random_30_30_0.5-event-state-01)
   (wm-fca-forget (wm-fca-random_30_30_0.5-event-state-00) (WMFCAScopeStamp (WMFCAPackedStamp random_30_30_0.5 object_000_g_0 attribute_000_m_0))))
(= (wm-fca-random_30_30_0.5-event-state-02)
   (wm-fca-remember (wm-fca-random_30_30_0.5-event-state-01) (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_000_m_0 WMTrue (WMFCAPackedStamp random_30_30_0.5 object_000_g_0 attribute_000_m_0) fcapy-controlled-random-509f45a3 random_30_30_0.5-generated-matrix)))
(= (wm-fca-random_30_30_0.5-event-state-03)
   (wm-fca-remember (wm-fca-random_30_30_0.5-event-state-02) (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_000_m_0 WMTrue (WMFCAPackedStamp random_30_30_0.5 object_000_g_0 attribute_000_m_0) fcapy-controlled-random-509f45a3 random_30_30_0.5-generated-matrix)))
(= (wm-fca-random_30_30_0.5-event-state-04)
   (wm-fca-remember (wm-fca-random_30_30_0.5-event-state-03) (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_000_m_0 WMFalse wm-fca-event-conflict-1 wm-fca-event-source-1 wm-fca-event-group-1)))
(= (wm-fca-random_30_30_0.5-event-state-05)
   (wm-fca-forget (wm-fca-random_30_30_0.5-event-state-04) (WMFCAScopeStamp wm-fca-event-conflict-1)))
(= (wm-fca-random_30_30_0.5-event-state-06)
   (wm-fca-remember (wm-fca-random_30_30_0.5-event-state-05) (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_002_m_2 WMUnknown wm-fca-event-explicit-unknown wm-fca-event-source-1 wm-fca-event-group-1)))
(= (wm-fca-random_30_30_0.5-event-state-07)
   (wm-fca-forget (wm-fca-random_30_30_0.5-event-state-06) (WMFCAScopeStamp wm-fca-event-explicit-unknown)))
(= (wm-fca-random_30_30_0.5-event-state-08)
   (wm-fca-remember (wm-fca-random_30_30_0.5-event-state-07) (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_000_m_0 WMTrue wm-fca-event-positive-1 wm-fca-event-source-1 wm-fca-event-group-1)))
(= (wm-fca-random_30_30_0.5-event-state-09)
   (wm-fca-remember (wm-fca-random_30_30_0.5-event-state-08) (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_000_m_0 WMTrue wm-fca-event-positive-1 wm-fca-event-source-1 wm-fca-event-group-1)))
(= (wm-fca-random_30_30_0.5-event-state-10)
   (wm-fca-revise (wm-fca-random_30_30_0.5-event-state-09) (WMFCAState (object_000_g_0 object_001_g_1 object_002_g_2 object_003_g_3 object_004_g_4 object_005_g_5 object_006_g_6 object_007_g_7 object_008_g_8 object_009_g_9 object_010_g_10 object_011_g_11 object_012_g_12 object_013_g_13 object_014_g_14 object_015_g_15 object_016_g_16 object_017_g_17 object_018_g_18 object_019_g_19 object_020_g_20 object_021_g_21 object_022_g_22 object_023_g_23 object_024_g_24 object_025_g_25 object_026_g_26 object_027_g_27 object_028_g_28 object_029_g_29) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9 attribute_010_m_10 attribute_011_m_11 attribute_012_m_12 attribute_013_m_13 attribute_014_m_14 attribute_015_m_15 attribute_016_m_16 attribute_017_m_17 attribute_018_m_18 attribute_019_m_19 attribute_020_m_20 attribute_021_m_21 attribute_022_m_22 attribute_023_m_23 attribute_024_m_24 attribute_025_m_25 attribute_026_m_26 attribute_027_m_27 attribute_028_m_28 attribute_029_m_29) (
       (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_000_m_0 WMFalse wm-fca-event-conflict-2 wm-fca-event-source-2 wm-fca-event-group-2)
       (WMFCAObservation random_30_30_0.5 object_000_g_0 attribute_002_m_2 WMTrue wm-fca-event-promote-false-cell wm-fca-event-source-2 wm-fca-event-group-2)
       (WMFCAObservation random_30_30_0.5-foreign-context object_000_g_0 attribute_000_m_0 WMTrue wm-fca-event-foreign-positive wm-fca-event-foreign-source wm-fca-event-foreign-group)))))
(= (wm-fca-random_30_30_0.5-event-state-11)
   (wm-fca-forget (wm-fca-random_30_30_0.5-event-state-10) (WMFCAScopeDependenceGroup wm-fca-event-group-2)))
(= (wm-fca-random_30_30_0.5-event-state-12)
   (wm-fca-forget (wm-fca-random_30_30_0.5-event-state-11) (WMFCAScopeSource fcapy-controlled-random-509f45a3)))
(= (wm-fca-random_30_30_0.5-event-state-13)
   (wm-fca-forget (wm-fca-random_30_30_0.5-event-state-12) (WMFCAScopeContext random_30_30_0.5-foreign-context)))
(= (wm-fca-random_30_30_0.5-event-state-14)
   (wm-fca-forget (wm-fca-random_30_30_0.5-event-state-13) (WMFCAScopeCell random_30_30_0.5 object_000_g_0 attribute_000_m_0)))

(= (wm-fca-random_30_30_0.5-event-query-candidates)
   (
   ()
   (attribute_000_m_0)
   (attribute_002_m_2)
   (attribute_000_m_0 attribute_002_m_2)
   (attribute_000_m_0 attribute_001_m_1)
   (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3)
   (attribute_029_m_29)))
