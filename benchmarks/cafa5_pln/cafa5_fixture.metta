; A dependence fixture, not biological benchmark data.
;
; homology-a and homology-b share a dependence group.  structure-c is in an
; independent group.  The expected group maxima are 0.8 and 0.5, giving a
; conservative cross-group maximum of 0.8 for protein-p / go-0001.

(cafa-prediction homology-a sequence-shared protein-p go-0001 0.8)
(cafa-prediction homology-b sequence-shared protein-p go-0001 0.7)
(cafa-prediction structure-c structure-independent protein-p go-0001 0.5)

(cafa-prediction homology-a sequence-shared protein-p go-0002 0.2)
