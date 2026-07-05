(= (web:url-encode $text)
   (function
     (case (__cetta_lib_web_url_encode $text)
       (($result (return $result))))))

(= (web:ddg-results-from-html $html $max-results)
   (function
     (case (__cetta_lib_web_ddg_results_from_html $html $max-results)
       (($result (return $result))))))
