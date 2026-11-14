; PeTTa expands registered translator rules when the equation is installed.
; Its existing compiler owns demand, fresh local names and source scopes.
!(import! &self (library outcome_kernel))
(: outcome:define (-> Atom Atom %Undefined%))
(= (outcome:define $head $body)
   (add-atom (context-space) (= $head $body)))
