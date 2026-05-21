; Rust-faithful exec-server server registry slice.
;
; This ports deterministic router registration from:
; - openai-codex/codex-rs/exec-server/src/server/registry.rs
;   - build_router
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores async closure handlers in `RpcRouter<ExecServerHandler>`.
;   This pure slice registers symbolic handler labels in the same request,
;   request-with-id, and notification slots. The method table and route
;   lookup behavior are preserved; actual handler invocation belongs with the
;   runtime bridge.

!(import! &self exec_server_rpc)
!(import! &self exec_server_process_protocol)
!(import! &self exec_server_file_system_protocol)
!(import! &self exec_server_http_protocol)

(= (codex:exec-server-registry-handler-initialized)
   (CodexExecServerRegistryHandlerInitialized))

(= (codex:exec-server-registry-handler-initialize)
   (CodexExecServerRegistryHandlerInitialize))

(= (codex:exec-server-registry-handler-http-request)
   (CodexExecServerRegistryHandlerHttpRequestWithId))

(= (codex:exec-server-registry-handler-exec)
   (CodexExecServerRegistryHandlerExec))

(= (codex:exec-server-registry-handler-exec-read)
   (CodexExecServerRegistryHandlerExecRead))

(= (codex:exec-server-registry-handler-exec-write)
   (CodexExecServerRegistryHandlerExecWrite))

(= (codex:exec-server-registry-handler-exec-terminate)
   (CodexExecServerRegistryHandlerExecTerminate))

(= (codex:exec-server-registry-handler-fs-read-file)
   (CodexExecServerRegistryHandlerFsReadFile))

(= (codex:exec-server-registry-handler-fs-write-file)
   (CodexExecServerRegistryHandlerFsWriteFile))

(= (codex:exec-server-registry-handler-fs-create-directory)
   (CodexExecServerRegistryHandlerFsCreateDirectory))

(= (codex:exec-server-registry-handler-fs-get-metadata)
   (CodexExecServerRegistryHandlerFsGetMetadata))

(= (codex:exec-server-registry-handler-fs-read-directory)
   (CodexExecServerRegistryHandlerFsReadDirectory))

(= (codex:exec-server-registry-handler-fs-remove)
   (CodexExecServerRegistryHandlerFsRemove))

(= (codex:exec-server-registry-handler-fs-copy)
   (CodexExecServerRegistryHandlerFsCopy))

(= (codex:exec-server-registry-build-router)
   (let $router-0 (codex:exec-server-rpc-router-new)
     (let $router-1
       (codex:exec-server-rpc-router-notification
         $router-0
         (codex:exec-server-protocol-initialized-method)
         (codex:exec-server-registry-handler-initialized))
       (let $router-2
         (codex:exec-server-rpc-router-request
           $router-1
           (codex:exec-server-protocol-initialize-method)
           (codex:exec-server-registry-handler-initialize))
         (let $router-3
           (codex:exec-server-rpc-router-request-with-id
             $router-2
             (codex:exec-server-http-request-method)
             (codex:exec-server-registry-handler-http-request))
           (let $router-4
             (codex:exec-server-rpc-router-request
               $router-3
               (codex:exec-server-protocol-exec-method)
               (codex:exec-server-registry-handler-exec))
             (let $router-5
               (codex:exec-server-rpc-router-request
                 $router-4
                 (codex:exec-server-protocol-exec-read-method)
                 (codex:exec-server-registry-handler-exec-read))
               (let $router-6
                 (codex:exec-server-rpc-router-request
                   $router-5
                   (codex:exec-server-protocol-exec-write-method)
                   (codex:exec-server-registry-handler-exec-write))
                 (let $router-7
                   (codex:exec-server-rpc-router-request
                     $router-6
                     (codex:exec-server-protocol-exec-terminate-method)
                     (codex:exec-server-registry-handler-exec-terminate))
                   (let $router-8
                     (codex:exec-server-rpc-router-request
                       $router-7
                       (codex:exec-server-fs-read-file-method)
                       (codex:exec-server-registry-handler-fs-read-file))
                     (let $router-9
                       (codex:exec-server-rpc-router-request
                         $router-8
                         (codex:exec-server-fs-write-file-method)
                         (codex:exec-server-registry-handler-fs-write-file))
                       (let $router-10
                         (codex:exec-server-rpc-router-request
                           $router-9
                           (codex:exec-server-fs-create-directory-method)
                           (codex:exec-server-registry-handler-fs-create-directory))
                         (let $router-11
                           (codex:exec-server-rpc-router-request
                             $router-10
                             (codex:exec-server-fs-get-metadata-method)
                             (codex:exec-server-registry-handler-fs-get-metadata))
                           (let $router-12
                             (codex:exec-server-rpc-router-request
                               $router-11
                               (codex:exec-server-fs-read-directory-method)
                               (codex:exec-server-registry-handler-fs-read-directory))
                             (let $router-13
                               (codex:exec-server-rpc-router-request
                                 $router-12
                                 (codex:exec-server-fs-remove-method)
                                 (codex:exec-server-registry-handler-fs-remove))
                               (codex:exec-server-rpc-router-request
                                 $router-13
                                 (codex:exec-server-fs-copy-method)
                                 (codex:exec-server-registry-handler-fs-copy)))))))))))))))))
