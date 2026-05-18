!(import! &self system)

!(assertEqual (get-type (system-cwd)) String)
!(assertEqual (get-type (system-os)) String)
!(assertEqual (system-has-args) False)
