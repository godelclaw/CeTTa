; An import whose module raises fails with the module's own error, as the
; reference loader rethrows it. The module is not left half loaded behind an
; import that seemed to succeed.
!(test (catch (import! &self ./import_errors_raising_lib.metta))
       (Error (existence_error source_sink ./import_errors_absent.metta)
              (context import! ./import_errors_absent.metta)))
!(test (collapse (raising-lib-tail)) ((raising-lib-tail)))
; An Error that a module's directive returns is that directive's answer, as at
; the top level: the module goes on loading.
!(import! &self ./import_errors_value_lib.metta)
!(test (value-lib-tail) loaded)
