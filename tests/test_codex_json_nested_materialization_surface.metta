!(import! &self json)

(= (json-materialization-inner)
   (JsonObject
     ((JsonPair "write" (JsonArray ((JsonString "/repo/runtime")))))))

(= (json-materialization-outer)
   (JsonObject
     ((JsonPair "permissions" (json-materialization-inner))
      (JsonPair "scope" (JsonString "turn")))))

!(assertEqual
  (json-stringify (json-materialization-outer))
  "{\"permissions\":{\"write\":[\"/repo/runtime\"]},\"scope\":\"turn\"}")
