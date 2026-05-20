; Narrow Rust-faithful core-skills model slice.
;
; This ports:
; - openai-codex/codex-rs/core-skills/src/model.rs
;
; Covered in this increment:
; - `SkillMetadata` core model shape, including `policy`
; - `SkillPolicy`
; - `SkillError`
; - `SkillLoadOutcome`
; - enabled/implicit-invocation filtering
; - product-restriction filtering for loaded skill outcomes
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores file systems and implicit skill indexes in `Arc<HashMap<...>>`.
;   This pure CeTTa boundary represents those maps as ordered entry lists. The
;   filtering algorithm preserves list order while applying the same key/value
;   retention predicates.
; - Rust uses `Option<T>` for optional policy fields and restriction product.
;   This slice uses the existing CeTTa `CodexAbsent` sentinel for `None`.
; - Rust `HashSet<AbsolutePathBuf>` disabled paths are represented as a list of
;   path strings. Membership and retention semantics match for unique paths;
;   duplicate disabled-path atoms are not introduced by this slice.

!(import! &self list)

(= (codex:core-skill-policy $allow-implicit-invocation $products)
   (CodexCoreSkillPolicy $allow-implicit-invocation $products))

(= (codex:core-skill-policy-allow-implicit-invocation
      (CodexCoreSkillPolicy $allow-implicit-invocation $products))
   $allow-implicit-invocation)

(= (codex:core-skill-policy-products
      (CodexCoreSkillPolicy $allow-implicit-invocation $products))
   $products)

(= (codex:core-skill-metadata
      $name
      $description
      $short-description
      $interface
      $dependencies
      $policy
      $path
      $scope)
   (CodexCoreSkillMetadata
     $name
     $description
     $short-description
     $interface
     $dependencies
     $policy
     $path
     $scope))

(= (codex:core-skill-metadata-name
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $name)

(= (codex:core-skill-metadata-description
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $description)

(= (codex:core-skill-metadata-short-description
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $short-description)

(= (codex:core-skill-metadata-interface
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $interface)

(= (codex:core-skill-metadata-dependencies
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $dependencies)

(= (codex:core-skill-metadata-policy
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $policy)

(= (codex:core-skill-metadata-path
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $path)

(= (codex:core-skill-metadata-scope
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $scope)

(= (codex:core-skill-metadata-from-protocol-skill
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled)
      $policy)
   (codex:core-skill-metadata
     $name
     $description
     $short-description
     $interface
     $dependencies
     $policy
     $path
     $scope))

(= (codex:core-skill-metadata-to-protocol-skill $skill $enabled)
   (CodexSkillMetadata
     (codex:core-skill-metadata-name $skill)
     (codex:core-skill-metadata-description $skill)
     (codex:core-skill-metadata-short-description $skill)
     (codex:core-skill-metadata-interface $skill)
     (codex:core-skill-metadata-dependencies $skill)
     (codex:core-skill-metadata-path $skill)
     (codex:core-skill-metadata-scope $skill)
     $enabled))

(= (codex:core-skill-error $path $message)
   (CodexCoreSkillError $path $message))

(= (codex:core-skill-error-path
      (CodexCoreSkillError $path $message))
   $path)

(= (codex:core-skill-error-message
      (CodexCoreSkillError $path $message))
   $message)

(= (codex:skill-file-system-entry $path $file-system)
   (CodexSkillFileSystemEntry $path $file-system))

(= (codex:skill-file-system-entry-path
      (CodexSkillFileSystemEntry $path $file-system))
   $path)

(= (codex:skill-file-system-entry-file-system
      (CodexSkillFileSystemEntry $path $file-system))
   $file-system)

(= (codex:core-skill-path-index-entry $path $skill)
   (CodexCoreSkillPathIndexEntry $path $skill))

(= (codex:core-skill-path-index-entry-path
      (CodexCoreSkillPathIndexEntry $path $skill))
   $path)

(= (codex:core-skill-path-index-entry-skill
      (CodexCoreSkillPathIndexEntry $path $skill))
   $skill)

(= (codex:core-skill-load-outcome
      $skills
      $errors
      $disabled-paths
      $file-systems-by-skill-path
      $implicit-skills-by-scripts-dir
      $implicit-skills-by-doc-path)
   (CodexCoreSkillLoadOutcome
     $skills
     $errors
     $disabled-paths
     $file-systems-by-skill-path
     $implicit-skills-by-scripts-dir
     $implicit-skills-by-doc-path))

(= (codex:core-skill-load-outcome-skills
      (CodexCoreSkillLoadOutcome
        $skills
        $errors
        $disabled-paths
        $file-systems-by-skill-path
        $implicit-skills-by-scripts-dir
        $implicit-skills-by-doc-path))
   $skills)

(= (codex:core-skill-load-outcome-errors
      (CodexCoreSkillLoadOutcome
        $skills
        $errors
        $disabled-paths
        $file-systems-by-skill-path
        $implicit-skills-by-scripts-dir
        $implicit-skills-by-doc-path))
   $errors)

(= (codex:core-skill-load-outcome-disabled-paths
      (CodexCoreSkillLoadOutcome
        $skills
        $errors
        $disabled-paths
        $file-systems-by-skill-path
        $implicit-skills-by-scripts-dir
        $implicit-skills-by-doc-path))
   $disabled-paths)

(= (codex:core-skill-load-outcome-file-systems-by-skill-path
      (CodexCoreSkillLoadOutcome
        $skills
        $errors
        $disabled-paths
        $file-systems-by-skill-path
        $implicit-skills-by-scripts-dir
        $implicit-skills-by-doc-path))
   $file-systems-by-skill-path)

(= (codex:core-skill-load-outcome-implicit-skills-by-scripts-dir
      (CodexCoreSkillLoadOutcome
        $skills
        $errors
        $disabled-paths
        $file-systems-by-skill-path
        $implicit-skills-by-scripts-dir
        $implicit-skills-by-doc-path))
   $implicit-skills-by-scripts-dir)

(= (codex:core-skill-load-outcome-implicit-skills-by-doc-path
      (CodexCoreSkillLoadOutcome
        $skills
        $errors
        $disabled-paths
        $file-systems-by-skill-path
        $implicit-skills-by-scripts-dir
        $implicit-skills-by-doc-path))
   $implicit-skills-by-doc-path)

(= (codex:core-skill-with-enabled $skill $enabled)
   (CodexCoreSkillWithEnabled $skill $enabled))

(= (codex:core-skill-with-enabled-skill
      (CodexCoreSkillWithEnabled $skill $enabled))
   $skill)

(= (codex:core-skill-with-enabled-enabled
      (CodexCoreSkillWithEnabled $skill $enabled))
   $enabled)

(= (codex:core-skill-list-contains-path () $path)
   False)

(= (codex:core-skill-list-contains-path $paths $path)
   (let $head (list:first $paths)
     (let $tail (list:rest $paths)
       (if (== $head $path)
           True
           (codex:core-skill-list-contains-path $tail $path)))))

(= (codex:core-skill-product-list-contains () $product)
   False)

(= (codex:core-skill-product-list-contains $products $product)
   (let $head (list:first $products)
     (let $tail (list:rest $products)
       (if (== $head $product)
           True
           (codex:core-skill-product-list-contains $tail $product)))))

(= (codex:core-skill-product-matches-product-restriction $product $products)
   (if (== $products ())
       True
       (codex:core-skill-product-list-contains $products $product)))

(= (codex:core-skill-allow-implicit-invocation $skill)
   (case (codex:core-skill-metadata-policy $skill)
     ((CodexAbsent True)
      ((CodexCoreSkillPolicy $allow-implicit-invocation $products)
       (if (== $allow-implicit-invocation CodexAbsent)
           True
           $allow-implicit-invocation)))))

(= (codex:core-skill-matches-product-restriction-for-product
      $skill
      $restriction-product)
   (case (codex:core-skill-metadata-policy $skill)
     ((CodexAbsent True)
      ((CodexCoreSkillPolicy $allow-implicit-invocation $products)
       (if (== $products ())
           True
           (if (== $restriction-product CodexAbsent)
               False
               (codex:core-skill-product-matches-product-restriction
                 $restriction-product
                 $products)))))))

(= (codex:core-skill-load-outcome-is-skill-enabled $outcome $skill)
   (not
     (codex:core-skill-list-contains-path
       (codex:core-skill-load-outcome-disabled-paths $outcome)
       (codex:core-skill-metadata-path $skill))))

(= (codex:core-skill-load-outcome-is-skill-allowed-for-implicit-invocation
      $outcome
      $skill)
   (and
     (codex:core-skill-load-outcome-is-skill-enabled $outcome $skill)
     (codex:core-skill-allow-implicit-invocation $skill)))

(= (codex:core-skill-load-outcome-allowed-skills-for-implicit-invocation
      $outcome)
   (codex:core-skill-load-outcome-allowed-skills-for-implicit-invocation-from
     (codex:core-skill-load-outcome-skills $outcome)
     $outcome))

(= (codex:core-skill-load-outcome-allowed-skills-for-implicit-invocation-from
      ()
      $outcome)
   ())

(= (codex:core-skill-load-outcome-allowed-skills-for-implicit-invocation-from
      $skills
      $outcome)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $tail-allowed
         (codex:core-skill-load-outcome-allowed-skills-for-implicit-invocation-from
           $tail
           $outcome)
         (if
           (codex:core-skill-load-outcome-is-skill-allowed-for-implicit-invocation
             $outcome
             $skill)
           (cons-atom $skill $tail-allowed)
           $tail-allowed)))))

(= (codex:core-skill-load-outcome-skills-with-enabled $outcome)
   (codex:core-skill-load-outcome-skills-with-enabled-from
     (codex:core-skill-load-outcome-skills $outcome)
     $outcome))

(= (codex:core-skill-load-outcome-skills-with-enabled-from () $outcome)
   ())

(= (codex:core-skill-load-outcome-skills-with-enabled-from $skills $outcome)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $enabled
         (codex:core-skill-load-outcome-is-skill-enabled $outcome $skill)
         (let $pair (codex:core-skill-with-enabled $skill $enabled)
           (let $tail-pairs
             (codex:core-skill-load-outcome-skills-with-enabled-from $tail $outcome)
             (cons-atom $pair $tail-pairs)))))))

(= (codex:core-skill-retained-paths $skills)
   (codex:core-skill-retained-paths-acc $skills ()))

(= (codex:core-skill-retained-paths-acc () $paths)
   $paths)

(= (codex:core-skill-retained-paths-acc $skills $paths)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $path (codex:core-skill-metadata-path $skill)
         (codex:core-skill-retained-paths-acc
           $tail
           (cons-atom $path $paths))))))

(= (codex:core-skill-filter-skills-for-product () $restriction-product)
   ())

(= (codex:core-skill-filter-skills-for-product $skills $restriction-product)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $tail-filtered
         (codex:core-skill-filter-skills-for-product $tail $restriction-product)
         (if
           (codex:core-skill-matches-product-restriction-for-product
             $skill
             $restriction-product)
           (cons-atom $skill $tail-filtered)
           $tail-filtered)))))

(= (codex:core-skill-retain-file-systems-by-path () $retained-paths)
   ())

(= (codex:core-skill-retain-file-systems-by-path $entries $retained-paths)
   (let $entry (list:first $entries)
     (let $tail (list:rest $entries)
       (let $tail-retained
         (codex:core-skill-retain-file-systems-by-path $tail $retained-paths)
         (if
           (codex:core-skill-list-contains-path
             $retained-paths
             (codex:skill-file-system-entry-path $entry))
           (cons-atom $entry $tail-retained)
           $tail-retained)))))

(= (codex:core-skill-retain-implicit-index-for-product () $restriction-product)
   ())

(= (codex:core-skill-retain-implicit-index-for-product $entries $restriction-product)
   (let $entry (list:first $entries)
     (let $tail (list:rest $entries)
       (let $skill (codex:core-skill-path-index-entry-skill $entry)
         (let $tail-retained
           (codex:core-skill-retain-implicit-index-for-product
             $tail
             $restriction-product)
           (if
             (codex:core-skill-matches-product-restriction-for-product
               $skill
               $restriction-product)
             (cons-atom $entry $tail-retained)
             $tail-retained))))))

(= (codex:filter-skill-load-outcome-for-product $outcome $restriction-product)
   (let $filtered-skills
     (codex:core-skill-filter-skills-for-product
       (codex:core-skill-load-outcome-skills $outcome)
       $restriction-product)
     (let $retained-paths (codex:core-skill-retained-paths $filtered-skills)
       (codex:core-skill-load-outcome
         $filtered-skills
         (codex:core-skill-load-outcome-errors $outcome)
         (codex:core-skill-load-outcome-disabled-paths $outcome)
         (codex:core-skill-retain-file-systems-by-path
           (codex:core-skill-load-outcome-file-systems-by-skill-path $outcome)
           $retained-paths)
         (codex:core-skill-retain-implicit-index-for-product
           (codex:core-skill-load-outcome-implicit-skills-by-scripts-dir $outcome)
           $restriction-product)
         (codex:core-skill-retain-implicit-index-for-product
           (codex:core-skill-load-outcome-implicit-skills-by-doc-path $outcome)
           $restriction-product)))))
