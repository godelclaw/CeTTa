; Regression for imported-module recursive list materialization.
; The ordinary let-recursive traversal for this shape can collapse after a
; large relative module import. map-atom-strict is the stable stdlib path for
; deterministic single-result mapping bodies.

!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

(= (strict-map-materialization-pair-key (StrictMapMaterializationPair $key $value))
   $key)

(= (strict-map-materialization-pair-value (StrictMapMaterializationPair $key $value))
   $value)

(= (strict-map-materialization-find-first $pairs $key)
   (let ($head $tail) (decons-atom $pairs)
     (if (== (strict-map-materialization-pair-key $head) $key)
         (strict-map-materialization-pair-value $head)
         (strict-map-materialization-find-first $tail $key))))

!(assertEqual
  (strict-map-materialization-find-first
    ((StrictMapMaterializationPair "a" A)
     (StrictMapMaterializationPair "b" B))
    "b")
  B)

!(assertEqual
  (map-atom-strict
    ("b" "a")
    $key
    (strict-map-materialization-find-first
      ((StrictMapMaterializationPair "a" A)
       (StrictMapMaterializationPair "b" B))
      $key))
  (B A))
