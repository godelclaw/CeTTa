; Generate PeTTa's expand-once spelling from the shared handler definitions.
; The source is parsed as data. No handler or described computation runs.
!(import! &self (library fs))
!(import! &self (library str))

(= (okgen:kept-lines $lines)
   (if (== $lines ()) ()
     (let* (($line (car-atom $lines)) ($trimmed (str:trim $line))
            ($rest (okgen:kept-lines (cdr-atom $lines))))
       (if (or (str:starts-with $trimmed ";") (str:starts-with $trimmed "!")) $rest
         (cons-atom $line $rest)))))
(= (okgen:macro? $head)
   (case $head
     ((outcome:bind True) (outcome:catch True) (outcome:report True) (outcome:if True)
      (outcome:choice True) (outcome:collapse True) (outcome:unique True)
      (outcome:intersection True) (outcome:subtraction True) ($other False))))
; PeTTa's explicit activation is eval. Its metta form returns an installed
; translator's quoted template as data rather than activating that template.
; Lower this host boundary while keeping the handler policy identical.
(= (okgen:lower $term)
   (if (== (get-metatype $term) Expression)
     (if (== $term ()) ()
       (if (== (car-atom $term) metta)
         (let* (($source (index-atom $term 1)) ($tail (cons-atom $source ())))
           (cons-atom eval $tail))
         (map-atom $term $part (okgen:lower $part))))
     $term))
(= (okgen:emit $form)
   (if (== (car-atom $form) =)
     (let* (($lhs (index-atom $form 1)) ($rhs (index-atom $form 2))
            ($head (car-atom $lhs)))
       (if (okgen:macro? $head)
         (let* (($body (okgen:lower $rhs))
                ($quoted (cons-atom quote ($body)))
                ($parts (cons-atom $lhs ($quoted)))
                ($rule (cons-atom = $parts)))
           (str:join "" ((repr $rule) "\n!(add-translator-rule! " (repr $head) ")\n")))
         (str:concat (repr $form) "\n")))
     (str:concat (repr $form) "\n")))
(= (okgen:forms $forms)
   (if (== $forms ()) ""
     (str:concat (okgen:emit (car-atom $forms)) (okgen:forms (cdr-atom $forms)))))
(= (okgen:render $source)
   (let* (($lines (str:split "\n" $source))
          ($kept (okgen:kept-lines $lines))
          ($forms (parse (str:join "" ("(" (str:join "\n" $kept) ")")))))
     (str:join "" ("; Generated from lib/outcome_kernel.metta by tools/generate_outcome_kernel.metta.\n"
       "; Handler policy has one source; PeTTa expands the held forms once.\n"
       (okgen:forms $forms)))))
(= (okgen:write $source $destination)
   (let $text (okgen:render (fs:read-text $source)) (fs:write $destination $text)))

(= (okgen:template $form $petta)
   (if (== (car-atom $form) =)
     (let* (($lhs (index-atom $form 1)) ($rhs (index-atom $form 2)) ($head (car-atom $lhs)))
       (if (okgen:macro? $head)
         (let* (($body (if $petta (okgen:lower $rhs) $rhs))
                ($body-tail (cons-atom $body ()))
                ($parts (cons-atom $lhs $body-tail))
                ($fact (cons-atom OutcomeKernelExpansion $parts)))
           (str:concat (repr $fact) "\n"))
         "")) ""))
(= (okgen:templates $forms $petta)
   (if (== $forms ()) ""
     (str:concat (okgen:template (car-atom $forms) $petta)
                 (okgen:templates (cdr-atom $forms) $petta))))
(= (okgen:write-templates $source $destination $petta)
   (let* (($lines (str:split "\n" (fs:read-text $source)))
          ($kept (okgen:kept-lines $lines))
          ($forms (parse (str:join "" ("(" (str:join "\n" $kept) ")"))))
          ($text (str:concat "; Generated outcome expansion templates; inert data, not executable definitions.\n"
                             (okgen:templates $forms $petta))))
     (fs:write $destination $text)))

; Run this entry under HE. The source must be read and printed in its
; target dialect: PeTTa truth symbols and HE Boolean literals differ.
(: okgen:he-template (-> Atom %Undefined%))
(= (okgen:he-template $form)
   (unify $form (= $lhs $rhs)
     (let ($head $arguments) (decons-atom $lhs)
       (if (okgen:macro? $head)
         (let* (($tail (cons-atom $rhs ())) ($parts (cons-atom $lhs $tail))
                ($fact (cons-atom OutcomeKernelExpansion $parts)))
           (str:concat (repr $fact) "\n")) "")) ""))
(: okgen:he-templates (-> Atom %Undefined%))
(= (okgen:he-templates $forms)
   (if-equal $forms () ""
     (let ($first $rest) (decons-atom $forms)
       (str:concat (okgen:he-template $first) (okgen:he-templates $rest)))))
(= (okgen:write-he-templates $source $destination)
   (let* (($lines (str:split "\n" (fs:read-text $source))) ($kept (okgen:kept-lines $lines))
          ($forms (parse (str:join "" ("(" (str:join "\n" $kept) ")"))))
          ($text (str:concat "; Generated HE outcome expansion templates; inert source syntax.\n"
                             (okgen:he-templates $forms))))
     (fs:write $destination $text)))
