
(define (check-vaquero-syntax prog)
    (define (checky form rest)
        (define (go-on ok)
            (if (not ok)
                #f
                (if (eq? rest '())
                    ok
                    (checky (car rest) (cdr rest)))))
        (if (list? form)
            (if (eq? form '())
                (go-on #t)
                (go-on
                    (let ((head (car form)))
                        (case head
                            ((def)      (check-vaquero-def form))
                            ((quote)    (check-vaquero-quote form))
                            ((if)       (check-vaquero-if form))
                            ((seq)      (check-vaquero-seq form))
                            ((set!)     (check-vaquero-set! form))
                            ((lambda)        (check-vaquero-lambda form))
                            ((proc)     (check-vaquero-proc form))
                            ((wall)     (check-vaquero-wall form))
                            ((gate)     (check-vaquero-gate form))
                            ((capture)  (check-vaquero-capture form))
                            ((guard)    (check-vaquero-guard form))
                            ((fail)     (check-vaquero-fail form))
                            ((ensure)   (check-vaquero-ensure form))
                            ((use)      (check-vaquero-use form))
                            ((export)   (check-vaquero-export form))
                            (else       #t)))))
            (go-on #t)))
    (if (and (pair? prog) (list? prog))
        (let ((first (car prog)))
            (if (and (pair? first) (eq? 'modules (car first)))
                (checky (cadr prog) (cddr prog)) ; skip (modules)
                (checky first (cdr prog))))
        #t))

(define (say x)
    (display x)
    (newline))

(define (syntax-error code e usage)
    (say "Syntax error:")
    (say code)
    (say e)
    (say usage)
    (newline)
    #f)

(define (check-vaquero-def code)
    (define usage '(def <name> <value>))
    (if (< (length code) 3)
        (syntax-error code "def: too few arguments." usage))
        (let ((name (cadr code)))
            (cond
                ((not (symbol? name))
                    (syntax-error code "def requires a symbol as its first argument." usage))
                ((< (length code) 3)
                    (syntax-error code "def: too few arguments" usage))
                ((> (length code) 3)
                    (syntax-error code "def: too many arguments" usage))
                ((holy? name)
                    (syntax-error code (string-join `("def:" ,(blasphemy name)) " ") usage))
                (else #t))))

(define (check-vaquero-quote code)
    (define usage '(quote <s-expression>))
    (if (not (eq? (length code) 2))
        (syntax-error code "quote takes one argument." usage)
        #t))

(define (check-vaquero-if code)
    (define usage '(if <predicate> <consequent> <alternative>))
    (if (< (length code) 4)
        (syntax-error code "if: too few arguments" usage)
        (if (> (length code) 4)
            (syntax-error code "if: too many arguments" usage)
            #t)))

(define (check-vaquero-seq code)
    (define usage '(seq <form> ...))
    (if (< (length code) 2)
        (syntax-error code "seq: empty sequences are forbidden." usage)
        #t))

(define (check-vaquero-op code)
    (define usage '(op <name> (<arg> ...) <body> ...))
    (if (< (length code) 4)
        (syntax-error code "op requires at least three arguments." usage))
    (let ((name (cadr code)))
        (cond
            ((not (symbol? (cadr code)))
                (syntax-error code "op requires a symbol as its first argument." usage))
            ((not (list? (caddr code)))
                (syntax-error code "op: second argument must be a list of formals." usage))
            ((< (length code) 4)
                (syntax-error code "op: at least one body form is required." usage))
            ((holy? name)
                (syntax-error code (string-join `("op:" ,(blasphemy name)) " ") usage))
            (else #t))))

(define (check-vaquero-lambda code)
    (define usage '(lambda (<arg> ...) <body>))
    (if (not (list? (cadr code)))
        (syntax-error code "lambda: second argument must be a list of formals." usage)
        (if (not (= (length code) 3))
            (syntax-error code "lambda: one body form is required; only one is allowed." usage)
            #t)))

(define (check-vaquero-proc code)
    (define usage '(proc <name?> (<arg> ...) <body> ...))
    (define arg1 (cadr code))
    (if (symbol? arg1)
        (let ((name arg1) (args (caddr code)))
           (if (holy? name)
               (syntax-error code (string-join `("proc:" ,(blasphemy name)) " ") usage)
               (if (not (list? args))
                   (syntax-error code "named proc: third argument must be a list of formals." usage)
                   (if (< (length code) 4)
                       (syntax-error code "proc: at least one body form is required." usage)
                       #t))))
        (let ((args arg1)) 
            (if (not (list? args))
                (syntax-error code "anon proc: second argument must be a list of formals." usage)
                (if (< (length code) 3)
                    (syntax-error code "proc: at least one body form is required." usage)
                    #t)))))

(define (check-vaquero-let code)
   (define usage '(let (<name> <value> ...) <body> ...))
   (if (not (list? (cadr code)))
      (syntax-error code "let: second argument must be a list of alternating names and values." usage)
      (if (< (length code) 3)
         (syntax-error code "let: one body form is required." usage)
         #t)))

(define (check-vaquero-wall code)
   (define usage '(wall (<name> <value> ...) <body> ...))
   (if (not (list? (cadr code)))
      (syntax-error code "wall: second argument must be a list of alternating names and values." usage)
      (if (< (length code) 3)
         (syntax-error code "wall: one body form is required." usage)
         #t)))

(define (check-vaquero-gate code)
    (define usage '(gate <body> ...))
    (if (< (length code) 2)
        (syntax-error code "gate: too few arguments." usage)
        #t))

(define (check-vaquero-capture code)
    (define usage '(capture <name> <body> ...))
    (if (< (length code) 3)
        (syntax-error code "capture: too few arguments." usage)
        (if (not (symbol? (cadr code)))
            (syntax-error code "capture requires a symbol as its first argument." usage)
            #t)))

(define (check-vaquero-guard code)
    (define usage '(guard (proc (error restart) <body> ...) <body> ...))
    (if (< (length code) 3)
        (syntax-error code "guard: too few arguments." usage)
        #t))
        
(define (check-vaquero-fail code)
    (define usage '(fail <object>))
    (if (< (length code) 2)
        (syntax-error code "fail: too few arguments." usage)
        (if (> (length code) 2)
            (syntax-error code "fail: too many arguments." usage)
            #t)))

(define (check-vaquero-use code)
    (define usage '(use <package-name> <source>))
    (if (< (length code) 3)
        (syntax-error code "use: too few arguments." usage)
        (let ((name (cadr code)) (uri (caddr code)))
            (if (not (symbol? name))
                (syntax-error code "use: package-name must be a symbol." usage)
                (if (not (or (symbol? uri) (string? uri)))
                    (syntax-error code "use: source must be a symbol or string." usage)
                    #t)))))

(define (check-vaquero-import code)
    (define usage '(import <package-name> <import-name> ...))
    (if (< (length code) 3)
        (syntax-error code "import: too few arguments." usage)
        (let ((package-name (cadr code)) (import-names (cddr code)))
            (if (not (symbol? package-name))
                (syntax-error code "import: package-name must be a symbol." usage)
                (if (not (every symbol? import-names))
                    (syntax-error code "import: import-names must be symbols." usage)
                    #t)))))

(define (check-vaquero-export code)
    (define usage '(syntax <name> <name> ...))
    (define (check x)
        (if (not (symbol? x))
            (syntax-error code "export: exported names must be symbols.")
            #t))
    (let ((rest (cdr code)))
        (if (not (pair? rest))
            (syntax-error code "export: must have at least 1 argument." usage)
            (let loop ((x (car rest)) (xs (cdr rest)))
                (if (check x)
                    (if (pair? xs)
                        (loop (car xs) (cdr xs))
                        #t)
                    #f)))))

