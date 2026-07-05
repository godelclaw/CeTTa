(: time:unix-time-ms (-> Number))

(= (time:sleep-ms $ms)
   (function
     (case (__cetta_lib_time_sleep_ms $ms)
       (($result (return $result))))))

(= (time:unix-time-ms)
   (function
     (case (__cetta_lib_time_unix_time_ms ())
       (($result (return $result))))))

(= (time:time-string)
   (function
     (case (__cetta_lib_time_time_string ())
       (($result (return $result))))))

(= (time:time-string $format)
   (function
     (case (__cetta_lib_time_time_string $format)
       (($result (return $result))))))
