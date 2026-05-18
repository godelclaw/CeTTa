!(import! &self system)

!(assertEqual (get-type (system-cwd)) String)
!(assertEqual (get-type (system-os)) String)
!(assertEqual (get-type (system-random-base64url-no-pad 16)) String)
!(assertEqual (system-has-args) False)
