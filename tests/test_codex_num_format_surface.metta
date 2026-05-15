!(register-module! ../codex)
!(import! &self codex:num_format)

!(assertEqualToResult
  (codex:format-with-separators 0)
  ("0"))

!(assertEqualToResult
  (codex:format-with-separators 12345)
  ("12,345"))

!(assertEqualToResult
  (codex:format-with-separators -12345)
  ("-12,345"))

!(assertEqualToResult
  (codex:format-si-suffix 0)
  ("0"))

!(assertEqualToResult
  (codex:format-si-suffix 999)
  ("999"))

!(assertEqualToResult
  (codex:format-si-suffix 1000)
  ("1.00K"))

!(assertEqualToResult
  (codex:format-si-suffix 1200)
  ("1.20K"))

!(assertEqualToResult
  (codex:format-si-suffix 10000)
  ("10.0K"))

!(assertEqualToResult
  (codex:format-si-suffix 100000)
  ("100K"))

!(assertEqualToResult
  (codex:format-si-suffix 999500)
  ("1.00M"))

!(assertEqualToResult
  (codex:format-si-suffix 1000000)
  ("1.00M"))

!(assertEqualToResult
  (codex:format-si-suffix 1234000)
  ("1.23M"))

!(assertEqualToResult
  (codex:format-si-suffix 12345678)
  ("12.3M"))

!(assertEqualToResult
  (codex:format-si-suffix 999950000)
  ("1.00G"))

!(assertEqualToResult
  (codex:format-si-suffix 1000000000)
  ("1.00G"))

!(assertEqualToResult
  (codex:format-si-suffix 1234000000)
  ("1.23G"))

!(assertEqualToResult
  (codex:format-si-suffix 1234000000000)
  ("1,234G"))

!(assertEqualToResult
  (codex:format-si-suffix -5)
  ("0"))
