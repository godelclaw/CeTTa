; A value service whose configuration first reads the FIFO named by
; CETTA_START_GATE, so a check can stop it while it is still starting.
!(import! &self (library system))
!(import! &self (library fs))

(= (start-gate:configuration)
  (let* (($gate (fs:read-text (system:getenv-or-default "CETTA_START_GATE" "")))
         ($socket (system:getenv-or-default "CETTA_START_SOCKET" "")))
    (ValueServiceV1 $socket $gate
      ((ServiceRouteV1 Gate Read start-gate:gate))
      (ServiceLimitsV1 4 4 1048576 30000 268435456 2147483647))))

(= (start-gate:gate (ServiceCallV1 $gate $peer $resource $unused)) (GateV1 $gate))
