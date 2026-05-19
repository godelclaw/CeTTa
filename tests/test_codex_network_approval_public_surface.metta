!(register-module! ../codex)
!(import! &self codex:network_approval)

!(assertEqual
  (codex:network-approval-protocol-from-network-protocol
    (codex:network-protocol-https-connect))
  (codex:network-approval-protocol-https))

!(assertEqual
  (codex:host-approval-key-from-request
    (codex:network-policy-request
      (codex:network-protocol-https-connect)
      "Example.COM"
      443))
  (codex:host-approval-key "example.com" "https" 443))

!(assertEqual
  (codex:network-approval-approval-id-for-key
    (codex:host-approval-key-from-request
      (codex:network-policy-request
        (codex:network-protocol-https-connect)
        "Example.COM"
        443)))
  "network#https#example.com#443")
