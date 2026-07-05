(= (vec:topk-jsonl $path $query-embedding $k)
   (function
     (case (__cetta_lib_vec_topk_jsonl $path $query-embedding $k)
       (($result (return $result))))))
