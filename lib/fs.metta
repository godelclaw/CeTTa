(= (fs-read-text $path)
   (function
     (case (__cetta_lib_fs_read_text $path)
       (($result (return $result))))))

(= (fs-write-text $path $text)
   (function
     (case (__cetta_lib_fs_write_text $path $text)
       (($result (return $result))))))

(= (fs-append-text $path $text)
   (function
     (case (__cetta_lib_fs_append_text $path $text)
       (($result (return $result))))))

(= (fs-create-dir-all $path)
   (function
     (case (__cetta_lib_fs_create_dir_all $path)
       (($result (return $result))))))

(= (fs-rename $from $to)
   (function
     (case (__cetta_lib_fs_rename $from $to)
       (($result (return $result))))))

(= (fs-remove-file $path)
   (function
     (case (__cetta_lib_fs_remove_file $path)
       (($result (return $result))))))

(= (fs-modified-unix-secs $path)
   (function
     (case (__cetta_lib_fs_modified_unix_secs $path)
       (($result (return $result))))))

(= (fs-exists? $path)
   (function
     (case (__cetta_lib_fs_exists $path)
       (($result (return $result))))))

(= (fs-read-lines $path)
   (function
     (case (__cetta_lib_fs_read_lines $path)
       (($result (return $result))))))

(= (fs-read-dir-entries $path)
   (function
     (case (__cetta_lib_fs_read_dir_entries $path)
       (($result (return $result))))))

(= (fs-path-kind $path)
   (function
     (case (__cetta_lib_fs_path_kind $path)
       (($result (return $result))))))

(= (fs-read-image-data-url $path)
   (function
     (case (__cetta_lib_fs_read_image_data_url $path)
       (($result (return $result))))))
