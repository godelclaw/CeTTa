!(register-module! ../codex)
!(import! &self path)
!(import! &self codex:permissions)
!(import! &self codex:config_permissions)
!(import! &self codex:network_proxy_loader)
!(import! &self codex:network_proxy_spec)

!(assertEqualToResult
  (codex:config-permissions-warning-list-from-unsupported-paths
    ("/tmp/**/*.log" ":project_roots/src/**/*.rs"))
  (("Filesystem glob `/tmp/**/*.log` uses `read` or `write` access, which is not fully supported by this platform's sandboxing. Use an exact path or trailing `/**` subtree rule instead. `none` deny-read globs are supported."
    "Filesystem glob `:project_roots/src/**/*.rs` uses `read` or `write` access, which is not fully supported by this platform's sandboxing. Use an exact path or trailing `/**` subtree rule instead. `none` deny-read globs are supported.")))

!(assertEqualToResult
  (codex:config-permissions-warning-list-from-unbounded-paths
    (":project_roots/**/*.env"))
  (("Filesystem deny-read glob `:project_roots/**/*.env` uses `**`. Non-macOS sandboxing does not support unbounded `**` natively; set `glob_scan_max_depth` in this filesystem profile to cap Linux glob expansion and silence this warning, or enumerate explicit depths such as `*.env`, `*/*.env`, and `*/*/*.env`.")))
