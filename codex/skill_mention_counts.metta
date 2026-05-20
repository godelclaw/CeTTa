; Narrow Rust-faithful core-skills mention-counts slice.
;
; This ports:
; - openai-codex/codex-rs/core-skills/src/mention_counts.rs
;
; Covered in this increment:
; - exact skill-name counts
; - ASCII-lowercase skill-name counts
; - exclusion of disabled skill paths
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust returns two `HashMap<String, usize>` values. This CeTTa surface uses
;   deterministic list-backed maps with the same lookup semantics. The Rust
;   callers only query by key, so iteration order is not observable there.

!(import! &self list)
!(import! &self str)

(= (codex:skill-name-count $name $count)
   (CodexSkillNameCount $name $count))

(= (codex:skill-name-count-name
      (CodexSkillNameCount $name $count))
   $name)

(= (codex:skill-name-count-count
      (CodexSkillNameCount $name $count))
   $count)

(= (codex:skill-name-counts $exact-counts $lower-counts)
   (CodexSkillNameCounts $exact-counts $lower-counts))

(= (codex:skill-name-counts-exact
      (CodexSkillNameCounts $exact-counts $lower-counts))
   $exact-counts)

(= (codex:skill-name-counts-lower
      (CodexSkillNameCounts $exact-counts $lower-counts))
   $lower-counts)

(= (codex:skill-mention-counts-skill-name
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $name)

(= (codex:skill-mention-counts-skill-path
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $path)

(= (codex:skill-mention-counts-list-contains $items $item)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head $item)
               True
               (codex:skill-mention-counts-list-contains $tail $item))))))

(= (codex:skill-mention-counts-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:skill-mention-counts-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:skill-mention-counts-ascii-lower-char
           (str-slice $text 0 1))
         (codex:skill-mention-counts-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:skill-name-count-list-get () $name)
   0)

(= (codex:skill-name-count-list-get $counts $name)
   (let $head (list:first $counts)
     (let $tail (list:rest $counts)
       (if (== (codex:skill-name-count-name $head) $name)
           (codex:skill-name-count-count $head)
           (codex:skill-name-count-list-get $tail $name)))))

(= (codex:skill-name-count-list-increment () $name)
   ((codex:skill-name-count $name 1)))

(= (codex:skill-name-count-list-increment $counts $name)
   (let $head (list:first $counts)
     (let $tail (list:rest $counts)
       (if (== (codex:skill-name-count-name $head) $name)
           (cons-atom
             (codex:skill-name-count
               $name
               (+ (codex:skill-name-count-count $head) 1))
             $tail)
           (case (codex:skill-name-count-list-increment $tail $name)
             (($updated-tail
               (cons-atom $head $updated-tail))))))))

(= (codex:build-skill-name-counts $skills $disabled-paths)
   (codex:build-skill-name-counts-acc $skills $disabled-paths () ()))

(= (codex:build-skill-name-counts-acc () $disabled-paths $exact-counts $lower-counts)
   (codex:skill-name-counts $exact-counts $lower-counts))

(= (codex:build-skill-name-counts-acc $skills $disabled-paths $exact-counts $lower-counts)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $path (codex:skill-mention-counts-skill-path $skill)
         (if (codex:skill-mention-counts-list-contains $disabled-paths $path)
             (codex:build-skill-name-counts-acc
               $tail
               $disabled-paths
               $exact-counts
               $lower-counts)
             (let $name (codex:skill-mention-counts-skill-name $skill)
               (let $lower-name
                 (codex:skill-mention-counts-ascii-lower-text $name)
                 (codex:build-skill-name-counts-acc
                   $tail
                   $disabled-paths
                   (codex:skill-name-count-list-increment $exact-counts $name)
                   (codex:skill-name-count-list-increment
                     $lower-counts
                     $lower-name)))))))))
