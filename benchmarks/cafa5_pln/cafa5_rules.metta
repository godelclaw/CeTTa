; Declarative CAFA5 leaf adapter and candidate rule.

(leaf-sig cafa-leaf-prediction
  (cafa-prediction $source $group $protein $term $score)
  (cafa-pred-fact $source $group $protein $term $score)
  (cafa-source-support $protein $term $group $source $score))

(rule-sig cafa-direct
  (-> (: $e (cafa-source-support $protein $term $group $source $score))
      (cafa-candidate $protein $term $group $source $score)))
