!(import! &self str)

(= (str-base64url-encode-no-pad $text)
   (function
     (case (__cetta_lib_str_base64_encode "__encode_url_no_pad" $text)
       (($result (return $result))))))

(= (str-base64url-decode $text)
   (function
     (case (__cetta_lib_str_base64_encode "__decode_url_no_pad" $text)
       (($result (return $result))))))
