(= (json-parse $text)
   (function
     (case (__cetta_lib_json_parse $text)
       (($result (return $result))))))

(= (json-stringify $value)
   (function
     (case (__cetta_lib_json_stringify $value)
       (($result (return $result))))))

(= (json-object-get $object $key)
   (function
     (case (__cetta_lib_json_object_get $object $key)
       (($result (return $result))))))

(= (json-string-value (JsonString $text))
   $text)

(= (json-number-value (JsonNumber $text))
   $text)

(= (json-bool-value (JsonBool $value))
   $value)

(= (json-array-items (JsonArray $items))
   $items)

(= (json-object-pairs (JsonObject $pairs))
   $pairs)
