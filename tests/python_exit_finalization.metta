; A run that ends normally finalizes its Python interpreter, as a Python host
; does: the output Python buffered is written, then its atexit handlers run,
; after the last answer. A run that skipped finalization lost both silently.
!((py-atom print) "python output buffered before exit")
!(let $handler ((py-atom atexit.register) (py-atom print) "python atexit handler ran") registered)
!(+ 1 2)
