(= (json-parse $text)
   (function
     (case (__cetta_lib_json_parse $text)
       (($result (return $result))))))

(= (json-materialize-pair (JsonPair $key $value))
   (JsonPair $key (json-materialize-value $value)))

(= (json-materialize (JsonObject $pairs))
   (JsonObject
     (map-atom-strict
       $pairs
       $pair
       (json-materialize-pair $pair))))

(= (json-materialize (JsonArray $items))
   (JsonArray
     (map-atom-strict
       $items
       $item
       (json-materialize $item))))

(= (json-materialize (JsonString $text))
   (JsonString $text))

(= (json-materialize (JsonNumber $text))
   (JsonNumber $text))

(= (json-materialize (JsonBool $value))
   (JsonBool $value))

(= (json-materialize JsonNull)
   JsonNull)

(= (json-materialize-value $value)
   (case (once (eval $value))
     (((JsonObject $pairs)
       (json-materialize (JsonObject $pairs)))
      ((JsonArray $items)
       (json-materialize (JsonArray $items)))
      ((JsonString $text)
       (JsonString $text))
      ((JsonNumber $text)
       (JsonNumber $text))
      ((JsonBool $inner)
       (JsonBool $inner))
      (JsonNull JsonNull))))

(= (json-materialize-top-value $value)
   (case $value
     (((JsonObject $pairs)
       (json-materialize (JsonObject $pairs)))
      ((JsonArray $items)
       (json-materialize (JsonArray $items)))
      ((JsonString $text)
       (JsonString $text))
      ((JsonNumber $text)
       (JsonNumber $text))
      ((JsonBool $inner)
       (JsonBool $inner))
      (JsonNull JsonNull)
      ($other $other))))

(= (json-stringify $value)
   (function
     (case (json-materialize-top-value $value)
       (($materialized
         (case (__cetta_lib_json_stringify $materialized)
           (($result (return $result)))))))))

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
