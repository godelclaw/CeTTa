!(import! &self str_base64url)

!(assertEqualToResult
  (str-base64url-encode-no-pad "f")
  ("Zg"))

!(assertEqualToResult
  (str-base64url-encode-no-pad "fo")
  ("Zm8"))

!(assertEqualToResult
  (str-base64url-encode-no-pad "foo")
  ("Zm9v"))

!(assertEqualToResult
  (str-base64url-encode-no-pad "{\"sub\":\"123\"}")
  ("eyJzdWIiOiIxMjMifQ"))

!(assertEqualToResult
  (str-base64url-encode-no-pad "~~~")
  ("fn5-"))

!(assertEqualToResult
  (str-base64url-decode "Zg")
  ("f"))

!(assertEqualToResult
  (str-base64url-decode "Zm8")
  ("fo"))

!(assertEqualToResult
  (str-base64url-decode "Zm9v")
  ("foo"))

!(assertEqualToResult
  (str-base64url-decode "eyJzdWIiOiIxMjMifQ")
  ("{\"sub\":\"123\"}"))

!(assertEqualToResult
  (str-base64url-decode "fn5-")
  ("~~~"))
