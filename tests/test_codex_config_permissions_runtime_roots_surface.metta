!(register-module! ../codex)
!(import! &self list)
!(import! &self path)
!(import! &self codex:permissions)
!(import! &self codex:config_permissions)

!(assertEqual
  (codex:config-permissions-runtime-absolute-path-list
    "/usr/bin/zsh")
  ("/usr/bin/zsh"))

!(assertEqual
  (codex:config-permissions-runtime-execve-wrapper-root
    "/home/user/.codex"
    "/home/user/.codex/tmp/arg0/session/codex-execve-wrapper")
  ("/home/user/.codex/tmp/arg0/session"))

!(assertEqual
  (codex:config-permissions-runtime-execve-wrapper-root
    "/home/user/.codex"
    "/opt/codex-execve-wrapper")
  ("/opt/codex-execve-wrapper"))

!(assertEqual
  (codex:config-permissions-runtime-absolute-path-list
    "relative-zsh")
  ())

!(assertEqual
  (codex:config-permissions-runtime-execve-wrapper-root
    "relative-codex-home"
    "relative-wrapper")
  ())
