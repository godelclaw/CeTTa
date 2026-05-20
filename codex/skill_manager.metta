; Narrow Rust-faithful core-skills manager helper slice.
;
; This ports the pure helper logic from:
; - openai-codex/codex-rs/core-skills/src/manager.rs
;
; Covered in this increment:
; - `SkillsLoadInput` data shape
; - `SkillRoot` data shape
; - `ConfigSkillsCacheKey` root/scope-rank construction
; - duplicate skill-root path retention
; - extra user root normalization, sorting, and deduplication
; - `finalize_skill_outcome`
; - product-filtered loaded outcome finalization order
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust manager caches are `RwLock<HashMap<...>>` and operate asynchronously
;   around filesystem loaders. This pure CeTTa boundary ports only the
;   deterministic value transformations used to build cache keys and finalize
;   loaded outcomes.
; - Rust canonicalizes extra roots with `Path::canonicalize().unwrap_or(root)`.
;   This slice uses lexical `path-normalize`, matching the current pure path
;   convention used by the adjacent skill loader/config slices until a shared
;   filesystem canonicalization layer is available here.
; - Rust stores implicit indexes in `Arc<HashMap<...>>`. This slice uses ordered
;   entry lists and prepends while scanning left-to-right, so first-match lookup
;   would observe the same last-writer-wins behavior as `HashMap::insert`.

!(import! &self list)
!(import! &self path)
!(import! &self skill_model)

(= (codex:skills-load-input
      $cwd
      $effective-skill-roots
      $config-layer-stack
      $bundled-skills-enabled)
   (CodexSkillsLoadInput
     $cwd
     $effective-skill-roots
     $config-layer-stack
     $bundled-skills-enabled))

(= (codex:skills-load-input-cwd
      (CodexSkillsLoadInput
        $cwd
        $effective-skill-roots
        $config-layer-stack
        $bundled-skills-enabled))
   $cwd)

(= (codex:skills-load-input-effective-skill-roots
      (CodexSkillsLoadInput
        $cwd
        $effective-skill-roots
        $config-layer-stack
        $bundled-skills-enabled))
   $effective-skill-roots)

(= (codex:skills-load-input-config-layer-stack
      (CodexSkillsLoadInput
        $cwd
        $effective-skill-roots
        $config-layer-stack
        $bundled-skills-enabled))
   $config-layer-stack)

(= (codex:skills-load-input-bundled-skills-enabled
      (CodexSkillsLoadInput
        $cwd
        $effective-skill-roots
        $config-layer-stack
        $bundled-skills-enabled))
   $bundled-skills-enabled)

(= (codex:skill-root $path $scope $file-system)
   (CodexSkillRoot $path $scope $file-system))

(= (codex:skill-root-path
      (CodexSkillRoot $path $scope $file-system))
   $path)

(= (codex:skill-root-scope
      (CodexSkillRoot $path $scope $file-system))
   $scope)

(= (codex:skill-root-file-system
      (CodexSkillRoot $path $scope $file-system))
   $file-system)

(= (codex:skill-manager-scope-rank (CodexSkillScopeRepo)) 0)
(= (codex:skill-manager-scope-rank (CodexSkillScopeUser)) 1)
(= (codex:skill-manager-scope-rank (CodexSkillScopeSystem)) 2)
(= (codex:skill-manager-scope-rank (CodexSkillScopeAdmin)) 3)

(= (codex:skill-manager-root-cache-key $path $scope-rank)
   (CodexSkillManagerRootCacheKey $path $scope-rank))

(= (codex:skill-manager-root-cache-key-from-root $root)
   (codex:skill-manager-root-cache-key
     (codex:skill-root-path $root)
     (codex:skill-manager-scope-rank (codex:skill-root-scope $root))))

(= (codex:skill-manager-root-cache-keys ())
   ())

(= (codex:skill-manager-root-cache-keys $roots)
   (let $root (list:first $roots)
     (let $tail (list:rest $roots)
       (let $key (codex:skill-manager-root-cache-key-from-root $root)
         (let $tail-keys (codex:skill-manager-root-cache-keys $tail)
           (cons-atom $key $tail-keys))))))

(= (codex:config-skills-cache-key $roots $skill-config-rules)
   (CodexConfigSkillsCacheKey
     (codex:skill-manager-root-cache-keys $roots)
     $skill-config-rules))

(= (codex:config-skills-cache-key-roots
      (CodexConfigSkillsCacheKey $roots $skill-config-rules))
   $roots)

(= (codex:config-skills-cache-key-skill-config-rules
      (CodexConfigSkillsCacheKey $roots $skill-config-rules))
   $skill-config-rules)

(= (codex:skill-manager-path-list-contains () $path)
   False)

(= (codex:skill-manager-path-list-contains $paths $path)
   (let $head (list:first $paths)
     (let $tail (list:rest $paths)
       (if (== $head $path)
           True
           (codex:skill-manager-path-list-contains $tail $path)))))

(= (codex:dedupe-skill-roots-by-path $roots)
   (list:reverse (codex:dedupe-skill-roots-by-path-acc $roots () ())))

(= (codex:dedupe-skill-roots-by-path-acc () $seen-paths $retained-roots)
   $retained-roots)

(= (codex:dedupe-skill-roots-by-path-acc $roots $seen-paths $retained-roots)
   (let $root (list:first $roots)
     (let $tail (list:rest $roots)
       (let $path-value (codex:skill-root-path $root)
         (if (codex:skill-manager-path-list-contains $seen-paths $path-value)
             (codex:dedupe-skill-roots-by-path-acc
               $tail
               $seen-paths
               $retained-roots)
             (codex:dedupe-skill-roots-by-path-acc
               $tail
               (cons-atom $path-value $seen-paths)
               (cons-atom $root $retained-roots)))))))

(= (codex:skill-manager-normalized-root-strings ())
   ())

(= (codex:skill-manager-normalized-root-strings $roots)
   (let $root (list:first $roots)
     (let $tail (list:rest $roots)
       (let $normalized-root (path-normalize $root)
         (let $tail-roots
           (codex:skill-manager-normalized-root-strings $tail)
           (cons-atom $normalized-root $tail-roots))))))

(= (codex:skill-manager-dedup-sorted-strings ())
   ())

(= (codex:skill-manager-dedup-sorted-strings $items)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (if (== $tail ())
           ($head)
           (let $dedup-tail (codex:skill-manager-dedup-sorted-strings $tail)
             (if (== $head (list:first $dedup-tail))
                 $dedup-tail
                 (cons-atom $head $dedup-tail)))))))

(= (codex:normalize-extra-user-roots $extra-user-roots)
   (let $normalized-roots
     (codex:skill-manager-normalized-root-strings $extra-user-roots)
     (case (sort-strings $normalized-roots)
       (($sorted-roots
         (codex:skill-manager-dedup-sorted-strings $sorted-roots))))))

(= (codex:skill-manager-implicit-skill-path-indexes
      $by-scripts-dir
      $by-skill-doc-path)
   (CodexSkillManagerImplicitSkillPathIndexes
     $by-scripts-dir
     $by-skill-doc-path))

(= (codex:skill-manager-implicit-skill-path-indexes-by-scripts-dir
      (CodexSkillManagerImplicitSkillPathIndexes
        $by-scripts-dir
        $by-skill-doc-path))
   $by-scripts-dir)

(= (codex:skill-manager-implicit-skill-path-indexes-by-skill-doc-path
      (CodexSkillManagerImplicitSkillPathIndexes
        $by-scripts-dir
        $by-skill-doc-path))
   $by-skill-doc-path)

(= (codex:skill-manager-build-implicit-skill-path-indexes $skills)
   (codex:skill-manager-build-implicit-skill-path-indexes-acc $skills () ()))

(= (codex:skill-manager-build-implicit-skill-path-indexes-acc
      ()
      $by-scripts-dir
      $by-skill-doc-path)
   (codex:skill-manager-implicit-skill-path-indexes
     $by-scripts-dir
     $by-skill-doc-path))

(= (codex:skill-manager-build-implicit-skill-path-indexes-acc
      $skills
      $by-scripts-dir
      $by-skill-doc-path)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $skill-doc-path
         (path-normalize (codex:core-skill-metadata-path $skill))
         (let $skill-dir (path-dirname (codex:core-skill-metadata-path $skill))
           (let $scripts-dir (path-normalize (path-join $skill-dir "scripts"))
             (let $scripts-entry
               (codex:core-skill-path-index-entry $scripts-dir $skill)
               (let $doc-entry
                 (codex:core-skill-path-index-entry $skill-doc-path $skill)
                 (codex:skill-manager-build-implicit-skill-path-indexes-acc
                   $tail
                   (cons-atom $scripts-entry $by-scripts-dir)
                   (cons-atom $doc-entry $by-skill-doc-path))))))))))

(= (codex:skill-manager-finalize-skill-outcome $outcome $disabled-paths)
   (let $outcome-with-disabled-paths
     (codex:core-skill-load-outcome
       (codex:core-skill-load-outcome-skills $outcome)
       (codex:core-skill-load-outcome-errors $outcome)
       $disabled-paths
       (codex:core-skill-load-outcome-file-systems-by-skill-path $outcome)
       ()
       ())
     (let $allowed-skills
       (codex:core-skill-load-outcome-allowed-skills-for-implicit-invocation
         $outcome-with-disabled-paths)
       (let $indexes
         (codex:skill-manager-build-implicit-skill-path-indexes $allowed-skills)
         (codex:core-skill-load-outcome
           (codex:core-skill-load-outcome-skills $outcome-with-disabled-paths)
           (codex:core-skill-load-outcome-errors $outcome-with-disabled-paths)
           (codex:core-skill-load-outcome-disabled-paths
             $outcome-with-disabled-paths)
           (codex:core-skill-load-outcome-file-systems-by-skill-path
             $outcome-with-disabled-paths)
           (codex:skill-manager-implicit-skill-path-indexes-by-scripts-dir
             $indexes)
           (codex:skill-manager-implicit-skill-path-indexes-by-skill-doc-path
             $indexes))))))

(= (codex:skill-manager-build-skill-outcome-from-loaded-outcome
      $loaded-outcome
      $restriction-product
      $disabled-paths)
   (codex:skill-manager-finalize-skill-outcome
     (codex:filter-skill-load-outcome-for-product
       $loaded-outcome
       $restriction-product)
     $disabled-paths))
