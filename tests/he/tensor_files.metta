; Standard tensor files: fixtures written by NumPy and safetensors themselves
; are copied, shared, refused with the reason, and written back.
!(import! &self lib_tensor)
!(tensor:to-expr (tensor:load "tests/fixtures/tensor_files/f64_2x3.npy"))
!(tensor:shape (tensor:map "tests/fixtures/tensor_files/f64_2x3.npy"))
!(tensor:map "tests/fixtures/tensor_files/f16_vector.npy")
!(tensor:to-expr (tensor:load "tests/fixtures/tensor_files/f16_vector.npy"))
!(tensor:to-expr (tensor:load "tests/fixtures/tensor_files/i32_fortran.npy"))
!(tensor:to-expr (tensor:map "tests/fixtures/tensor_files/mixed.safetensors" "ids"))
!(tensor:to-expr (tensor:load "tests/fixtures/tensor_files/bf16.safetensors"))
!(tensor:load "tests/fixtures/tensor_files/mixed.safetensors")
!(tensor:load "tests/fixtures/tensor_files/mixed.safetensors" "absent")
!(tensor:file-info "tests/fixtures/tensor_files/bf16.safetensors")
!(tensor:save-npy "runtime/tensor_files_he.npy" (tensor:from f32 (2 2) (0.5 1.5 -2 4)))
!(tensor:to-expr (tensor:map "runtime/tensor_files_he.npy"))
!(tensor:save-safetensors "runtime/tensor_files_he.safetensors" (("v" (tensor:from f64 (2) (1 2))) ("n" (tensor:from u8 (1) (7)))) (("k" "v")))
!(tensor:map-all "runtime/tensor_files_he.safetensors")
!(let ($o $b) (tensor:string-column ("ab" "" "é")) (tensor:strings $o $b))
!(let ($o $b) (tensor:string-column ("ab" "" "é")) (tensor:string-at $o $b 2))
; f32 rows, as loaded embeddings often are, read as their exact f64 values.
!(tensor:to-expr (tensor:row-norms (tensor:from f32 (2 2) (3 4 0 0.5))))
!(tensor:to-expr (tensor:normalize-rows (tensor:from f32 (2 2) (3 4 0 0.5))))
!(tensor:dtype (tensor:normalize-rows (tensor:from f32 (2 2) (3 4 0 0.5))))
; A string column's rows by value: a hash table of its rows, the row of a
; string, and masks of the rows equal to a string or to a value.
!(let ($o $b) (tensor:string-column ("ab" "" "é" "x")) (let $i (tensor:string-index $o $b) ((tensor:shape $i) (tensor:string-find $i $o $b "é") (tensor:string-find $i $o $b "zz") (tensor:to-expr (tensor:string-mask $o $b "x")))))
!(let ($o $b) (tensor:string-column ("a" "b" "a")) (tensor:string-index $o $b))
!(tensor:to-expr (tensor:mask-equal (tensor:from i64 (4) (1 2 3 2)) 2))
!(tensor:to-expr (tensor:mask-equal (tensor:from f32 (3) (0.5 -0.0 2)) 0.0))
!(tensor:mask-equal (tensor:from i64 (2) (1 2)) "x")
!(tensor:to-booleans (tensor:from u8 (3) (1 0 1)))
!(tensor:to-booleans (tensor:from u8 (1) (2)))
; open-all shares each tensor it can and copies the others; an entry
; (name tensor bool) is saved as BOOL.
!(let (TensorFile $f $entries $m) (tensor:open-all "tests/fixtures/tensor_files/mixed.safetensors") (collapse (let ($name $t) (superpose $entries) ($name (tensor:dtype $t)))))
!(tensor:save-safetensors "runtime/tensor_files_he_bool.safetensors" (("flag" (tensor:from u8 (3) (1 0 1)) bool) ("n" (tensor:from i64 (1) (7)))))
!(tensor:file-info "runtime/tensor_files_he_bool.safetensors")
!(tensor:save-safetensors "runtime/tensor_files_he_bool.safetensors" (("flag" (tensor:from u8 (1) (2)) bool)))
