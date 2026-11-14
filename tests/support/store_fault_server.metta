; A one-store service shaped like an input ledger: the owner is opened once at
; configuration, and each write runs as a db transaction next to the store.
; Its maintenance hook writes too, once per FaultLater request, and FaultWait
; holds the service until a line can be read from the named FIFO.
; Used by check_store_write_faults.py with an injected write fault.
!(import! &self (library db))
!(import! &self (library system))
!(import! &self (library fs))
!(change-state! fault-server:later none)

(= (fault-server:configuration)
  (let* (($path (system:getenv-or-default "CETTA_DB_SOURCE" ""))
         ($socket (system:getenv-or-default "CETTA_DB_SOCKET" "")))
    (case (db:open $path)
      (((Error $where $why) (Error $where $why))
       ($owner
        (ValueServiceV2 $socket $owner
          ((ServiceRouteV1 FaultPut Write fault-server:put)
           (ServiceRouteV1 FaultLater Write fault-server:later)
           (ServiceRouteV1 FaultRows Read fault-server:rows)
           (ServiceRouteV1 FaultWait Read fault-server:wait))
          (ServiceLimitsV1 8 16 1048576 30000 268435456 2147483647)
          (ServiceMaintenanceV1 fault-server:maintenance FaultIdleV1 1)))))))

; The outcome is returned as data, an Error included.
(= (fault-server:write $owner $request $key)
  (let $outcome (db:transaction-result $owner data $request put
                  (|-> ($space) (let $_ (add-atom $space (row $key)) (stored $key))))
    (FaultOutcomeV1 $outcome)))

; One row per request; a repeated request replays its first answer.
(= (fault-server:put (ServiceCallV1 $owner $peer $resource (FaultPutV1 $request $key)))
  (fault-server:write $owner $request $key))

; The row is written by the maintenance step that follows this request.
(= (fault-server:later (ServiceCallV1 $owner $peer $resource (FaultLaterV1 $request $key)))
  (let $_ (change-state! fault-server:later ($request $key)) (FaultLaterV1 $request)))

(= (fault-server:maintenance (ServiceMaintenanceCallV1 $owner $state $work))
  (case (get-state fault-server:later)
    ((none (ServiceMaintenanceIdleV1 FaultIdleV1 FaultNothingV1))
     (($request $key)
      (let* (($_ (change-state! fault-server:later none))
             ($outcome (fault-server:write $owner $request $key)))
        (ServiceMaintenanceIdleV1 FaultIdleV1 (FaultWroteV1 $outcome)))))))

(= (fault-server:wait (ServiceCallV1 $owner $peer $resource (FaultWaitV1 $path)))
  (FaultWaitedV1 (fs:read-text $path)))

(= (fault-server:rows (ServiceCallV1 $owner $peer $resource $unused))
  (case (db:snapshot $owner data)
    (((Error $where $why) (Error $where $why))
     ($view (let* (($rows (collapse (match $view (row $key) $key)))
                   ($_ (db:close $view)))
              (FaultRowsV1 $rows))))))

; The same store held by a parent-owned worker (cetta-value-worker without
; --serve) across its requests.
(= (fault-worker:run (FaultOpenV1 $path))
  (let $owner (db:open $path) (let $_ (change-state! fault-worker:owner $owner) FaultOpenedV1)))
(= (fault-worker:run (FaultPutV1 $request $key))
  (fault-server:write (get-state fault-worker:owner) $request $key))
