!(register-module! ../codex)
!(import! &self codex:auth)
!(import! &self codex:token_data)

(= (codex-token-data-jwt-pro)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9wbGFuX3R5cGUiOiJwcm8ifX0.c2ln")

(= (codex-token-data-jwt-go)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9wbGFuX3R5cGUiOiJnbyJ9fQ.c2ln")

(= (codex-token-data-jwt-hc)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9wbGFuX3R5cGUiOiJoYyJ9fQ.c2ln")

(= (codex-token-data-jwt-missing)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiIxMjMifQ.c2ln")

(= (codex-token-data-jwt-fedramp)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9hY2NvdW50X2lkIjoiYWNjb3VudC1mZWQiLCJjaGF0Z3B0X2FjY291bnRfaXNfZmVkcmFtcCI6dHJ1ZX19.c2ln")

(= (codex-token-data-jwt-profile)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJodHRwczovL2FwaS5vcGVuYWkuY29tL3Byb2ZpbGUiOnsiZW1haWwiOiJwcm9maWxlQGV4YW1wbGUuY29tIn19.c2ln")

(= (codex-token-data-jwt-user-fallback)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsidXNlcl9pZCI6ImZhbGxiYWNrLXVzZXIifX0.c2ln")

(= (codex-token-data-jwt-user-prefer-chatgpt)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF91c2VyX2lkIjoiY2hhdGdwdC11c2VyIiwidXNlcl9pZCI6ImZhbGxiYWNrLXVzZXIifX0.c2ln")

(= (codex-token-data-jwt-business)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9wbGFuX3R5cGUiOiJzZWxmX3NlcnZlX2J1c2luZXNzX3VzYWdlX2Jhc2VkIn19.c2ln")

(= (codex-token-data-jwt-enterprise-cbp)
   "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9wbGFuX3R5cGUiOiJlbnRlcnByaXNlX2NicF91c2FnZV9iYXNlZCJ9fQ.c2ln")

(= (codex-token-data-parse-info $jwt)
   (codex:id-token-info-parse-result-value
     (codex:parse-chatgpt-jwt-claims $jwt)))

!(assertEqualToResult
  (codex:id-token-info-email
    (codex-token-data-parse-info (codex-token-data-jwt-pro)))
  ("user@example.com"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-parse-info (codex-token-data-jwt-pro)))
  ("Pro"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-parse-info (codex-token-data-jwt-go)))
  ("Go"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-parse-info (codex-token-data-jwt-hc)))
  ("Enterprise"))

!(assertEqualToResult
  (codex:id-token-info-is-workspace-account
    (codex-token-data-parse-info (codex-token-data-jwt-hc)))
  (True))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-parse-info (codex-token-data-jwt-business)))
  ("Self Serve Business Usage Based"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type-raw
    (codex-token-data-parse-info (codex-token-data-jwt-business)))
  ("self_serve_business_usage_based"))

!(assertEqualToResult
  (codex:id-token-info-is-workspace-account
    (codex-token-data-parse-info (codex-token-data-jwt-business)))
  (True))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-parse-info (codex-token-data-jwt-enterprise-cbp)))
  ("Enterprise CBP Usage Based"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type-raw
    (codex-token-data-parse-info (codex-token-data-jwt-enterprise-cbp)))
  ("enterprise_cbp_usage_based"))

!(assertEqualToResult
  (codex:id-token-info-is-workspace-account
    (codex-token-data-parse-info (codex-token-data-jwt-enterprise-cbp)))
  (True))

!(assertEqualToResult
  (codex:id-token-info-email
    (codex-token-data-parse-info (codex-token-data-jwt-missing)))
  (CodexAbsent))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-parse-info (codex-token-data-jwt-missing)))
  (CodexAbsent))

!(assertEqualToResult
  (codex:id-token-info-is-fedramp-account
    (codex-token-data-parse-info (codex-token-data-jwt-missing)))
  (False))

!(assertEqualToResult
  (codex:id-token-info-chatgpt-account-id
    (codex-token-data-parse-info (codex-token-data-jwt-fedramp)))
  ("account-fed"))

!(assertEqualToResult
  (codex:id-token-info-is-fedramp-account
    (codex-token-data-parse-info (codex-token-data-jwt-fedramp)))
  (True))

!(assertEqualToResult
  (codex:id-token-info-email
    (codex-token-data-parse-info (codex-token-data-jwt-profile)))
  ("profile@example.com"))

!(assertEqualToResult
  (codex:id-token-info-chatgpt-user-id
    (codex-token-data-parse-info (codex-token-data-jwt-user-fallback)))
  ("fallback-user"))

!(assertEqualToResult
  (codex:id-token-info-chatgpt-user-id
    (codex-token-data-parse-info (codex-token-data-jwt-user-prefer-chatgpt)))
  ("chatgpt-user"))

!(assertEqualToResult
  (codex:id-token-info-raw-jwt
    (codex-token-data-parse-info (codex-token-data-jwt-pro)))
  ("eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9wbGFuX3R5cGUiOiJwcm8ifX0.c2ln"))

!(assertEqualToResult
  (codex:id-token-info-parse-result-reason
    (codex:parse-chatgpt-jwt-claims "not-a-jwt"))
  (CodexIdTokenInfoErrorInvalidFormat))
