
(define (start)
    (define args (command-line-arguments))
    (define (fname)
        (if (pair? (cdr args))
            (cadr args)
            (usage)))
    (define (prep-dir path)
        (if (not (directory? path))
            (create-directory path #t)
            #f))
    (prep-dir vaquero-mod-dir)
    (prep-dir vaquero-cache-dir)
    (if (not (file-exists? vaquero-use-symbols))
        (with-output-to-file vaquero-use-symbols
            (lambda ()
                (write-string symbols.vaq))))
    (global-env)
    (if (member "--skip-prelude" args)
        #f
        (begin
            (add-global-prelude)
            (symbols-env)))
    (if (not (pair? args))
        (usage)
        (let ((cmd (string->symbol (car args))))
            (case cmd
                ((repl) (vaquero-repl))
                ((eval) 
                    (let ((code-str (fname)))
                        (define code
                            (vaquero-read-file
                                (open-input-string code-str)))
                        (define expanded
                            (vaquero-expand code (cli-env)))
                        (if (check-vaquero-syntax expanded)
                            (vaquero-run expanded)
                            (exit))))
                ((run)
                    (let ((expanded (read-expand-cache-prog (fname) (cli-env))))
                        (if (check-vaquero-syntax expanded)
                            (vaquero-run expanded)
                            (exit))))
                ((check)
                    (let ((its-good (check-vaquero-syntax (cdr (read-expand-cache-prog (fname) (cli-env))))))
                        (display "Syntax check complete: ")
                        (say (if its-good 'ok 'FAIL))))
                ((clean)
                    (let ((cached (append (glob "~/.vaquero/expanded/*") (glob "~/.vaquero/modules/*") (list "~/.vaquero/global.vaq"))))
                        (let loop ((f (car cached)) (fs (cdr cached)))
                            (delete-file* f)
                            (if (eq? fs '())
                                (display "Cache cleared.\n")
                                (loop (car fs) (cdr fs))))))
                ((compile)
                    (let ((expanded (read-expand-cache-prog (fname) (cli-env))))
                        (debug "Wrote compiled file to " (get-vaquero-cached-path (find-file (cadr args))))))
                ((expand)
                    (begin
                        (pp
                            (vaquero-view
                                (read-expand-cache-prog (fname) (cli-env))))
                        (newline)))
                (else (printf "Unknown command: ~A~%" cmd))))))
