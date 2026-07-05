; HE-backed runtime interface: println! returns unit, so binding against ()
; should continue through let*.

!(let* (
    (() (println! "bind-unit"))
    ($x ok)
  )
  $x)
