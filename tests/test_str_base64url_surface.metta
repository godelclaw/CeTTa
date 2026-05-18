!(import! &self str_base64url)

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
