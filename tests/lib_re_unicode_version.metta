; The regex library names the Unicode version of its property classes, and
; the classes are that version's: U+1C89, a letter assigned in Unicode 16.0,
; is \p{L}, and U+1C8B, unassigned there, is \p{Cn}.
!(import! &self (library re))
!(import! &self (library str))
!(println! (VERSION (re:unicode-version)))
!(println! (LETTER (re:is-match (re:compile "^\\p{L}$") (str:from-codepoints (7305)))))
!(println! (UNASSIGNED (re:is-match (re:compile "^\\p{Cn}$") (str:from-codepoints (7307)))))
