!(register-module! ../codex)
!(import! &self codex:account)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:rate-limit-reached-type-rate-limit-reached)
  ("rate_limit_reached"))

!(assertEqualToResult
  (codex:rate-limit-reached-type-workspace-owner-credits-depleted)
  ("workspace_owner_credits_depleted"))

!(assertEqualToResult
  (codex:rate-limit-window-used-percent
    (codex:rate-limit-window 37.5 60 1712345678))
  (37.5))

!(assertEqualToResult
  (codex:rate-limit-window-window-minutes
    (codex:rate-limit-window 37.5 60 1712345678))
  (60))

!(assertEqualToResult
  (codex:rate-limit-window-resets-at
    (codex:rate-limit-window 37.5 60 1712345678))
  (1712345678))

!(assertEqualToResult
  (codex:credits-snapshot-has-credits
    (codex:credits-snapshot True False "$12.34"))
  (True))

!(assertEqualToResult
  (codex:credits-snapshot-unlimited
    (codex:credits-snapshot True False "$12.34"))
  (False))

!(assertEqualToResult
  (codex:credits-snapshot-balance
    (codex:credits-snapshot True False "$12.34"))
  ("$12.34"))

!(assertEqualToResult
  (codex:rate-limit-snapshot-plan-type
    (codex:rate-limit-snapshot
      "limit-1"
      "Starter"
      (codex:rate-limit-window 12.5 5 1712000000)
      CodexAbsent
      (codex:credits-snapshot True False "$12.34")
      (codex:plan-type-pro)
      (codex:rate-limit-reached-type-workspace-member-usage-limit-reached)))
  ((CodexPlanTypePro)))

!(assertEqualToResult
  (codex:rate-limit-snapshot-rate-limit-reached-type
    (codex:rate-limit-snapshot
      "limit-1"
      "Starter"
      (codex:rate-limit-window 12.5 5 1712000000)
      CodexAbsent
      (codex:credits-snapshot True False "$12.34")
      (codex:plan-type-pro)
      (codex:rate-limit-reached-type-workspace-member-usage-limit-reached)))
  ("workspace_member_usage_limit_reached"))

!(assertEqualToResult
  (codex:rate-limit-snapshot-primary
    (codex:token-count-event-rate-limits
      (codex:token-count-event
        CodexAbsent
        (codex:rate-limit-snapshot
          "limit-1"
          "Starter"
          (codex:rate-limit-window 12.5 5 1712000000)
          (codex:rate-limit-window 88.0 CodexAbsent CodexAbsent)
          (codex:credits-snapshot True False "$12.34")
          CodexAbsent
          CodexAbsent))))
  ((CodexRateLimitWindow 12.5 5 1712000000)))

!(assertEqualToResult
  (codex:rate-limit-snapshot-secondary
    (codex:rate-limit-snapshot
      "limit-1"
      "Starter"
      (codex:rate-limit-window 12.5 5 1712000000)
      (codex:rate-limit-window 88.0 CodexAbsent CodexAbsent)
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  ((CodexRateLimitWindow 88.0 CodexAbsent CodexAbsent)))
