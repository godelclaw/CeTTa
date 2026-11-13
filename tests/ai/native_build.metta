; Compile isolated qualification objects from the actual Make-generated
; response files. Never replace the production objects or executable.
!(import! &self (library proc))
!(import! &self (library str))
!(import! &self (library system))
(= (nb:run $compiler $files $cwd $count)
   (if (== $files ()) (NativeBuildPass $count)
     (let* (($file (car-atom $files)) ($rest (cdr-atom $files))
            ($response (str:concat "@" $file)))
       (case (proc:run ($compiler $response) $cwd inherit 300000 1048576)
         (((proc:exited 0 $out $err) (nb:run $compiler $rest $cwd (+ $count 1)))
          ($other (let $shown (println! (NativeBuildFailed $file $other)) (system:exit 1))))))))
