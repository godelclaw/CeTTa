!(import! &self fs)
!(import! &self web)

!(assertEqual
  (web:url-encode "a b+c/&")
  "a+b%2Bc%2F%26")

!(assertEqual
  (web:ddg-results-from-html
    (fs:read-text "tests/fixtures/ddg_lite_sample.html")
    5)
  (JsonArray
    ((JsonObject
       ((JsonPair "title" (JsonString "Example & Result"))
        (JsonPair "url" (JsonString "https://example.com/a?x=1"))
        (JsonPair "snippet" (JsonString "A snippet 'here'"))))
     (JsonObject
       ((JsonPair "title" (JsonString "Second Result"))
        (JsonPair "url" (JsonString "https://example.org/b"))
        (JsonPair "snippet" (JsonString "Another snippet")))))))
