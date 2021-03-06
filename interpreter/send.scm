
(include "bool.scm")
(include "eof.scm")
(include "null.scm")
(include "number.scm")
(include "symbol.scm")
(include "text.scm")
(include "pair.scm")
(include "tuple.scm")
(include "set.scm")
(include "proc.scm")
(include "stream.scm")
(include "vector.scm")
(include "table.scm")
(include "env.scm")

(define vaquero-universal-messages '(answers? autos messages to-bool to-text type view))

(define (vaquero-send obj msg cont err)
   (define obj-type (vaquero-type obj))
   (define handler (htr vaquero-send-vtable obj-type))
   (handler obj msg cont err))

(define (vaquero-send-atomic obj msg)
    (vaquero-send obj msg top-cont top-err))

(define (vaquero-answerer msgs)
   (define msgs+ (append msgs vaquero-universal-messages))
   (lambda (msg)
      (if (member msg msgs+) #t #f)))

(define (vaquero-send-generic vtable)
   (lambda (obj msg cont err)
      (define m
         (if (hte? vtable msg)
            (htr vtable msg)
            (htr vtable 'default)))
      (m obj msg cont err)))

(define vaquero-send-null
   (vaquero-send-generic vaquero-send-null-vtable))

(define vaquero-send-bool
   (vaquero-send-generic vaquero-send-bool-vtable))

(define vaquero-send-symbol
   (vaquero-send-generic vaquero-send-symbol-vtable))

(define vaquero-send-int
   (vaquero-send-generic vaquero-send-int-vtable))

(define vaquero-send-real
   (vaquero-send-generic vaquero-send-real-vtable))

(define vaquero-send-text
   (vaquero-send-generic vaquero-send-text-vtable))

(define vaquero-send-list
   (vaquero-send-generic vaquero-send-list-vtable))

(define vaquero-send-pair
   (vaquero-send-generic vaquero-send-pair-vtable))

(define vaquero-send-tuple
   (vaquero-send-generic vaquero-send-tuple-vtable))

(define vaquero-send-set
   (vaquero-send-generic vaquero-send-set-vtable))

(define vaquero-send-primitive
   (vaquero-send-generic vaquero-send-primitive-vtable))

(define vaquero-send-proc
   (vaquero-send-generic vaquero-send-proc-vtable))

(define vaquero-send-env
   (vaquero-send-generic vaquero-send-env-vtable))

(define vaquero-send-vector
   (vaquero-send-generic vaquero-send-vector-vtable))

(define vaquero-send-table
   (vaquero-send-generic vaquero-send-table-vtable))

(define vaquero-send-source
   (vaquero-send-generic vaquero-send-source-vtable))

(define vaquero-send-sink
   (vaquero-send-generic vaquero-send-sink-vtable))

(define vaquero-send-EOF
   (vaquero-send-generic vaquero-send-EOF-vtable))

(define (vaquero-send-wtf obj msg cont err)
   (err (vaquero-error-object 'wtf-was-that? `(send ,obj ,msg) "Unknown object!")))

(define (vaquero-send-object obj msg cont err)
   (define fields   (vaquero-obj-fields obj))
   (define forwards (vaquero-obj-forwards obj))
   (define autos    (vaquero-obj-autos obj))
   (define (get-msgs)
      (append (htks fields) (htks forwards)))
   (case msg
      ; unshadowable reflection messages
      ((answers?)  (cont (vaquero-answerer (get-msgs))))
      ((messages)  (cont (get-msgs)))
      ((autos)     (cont (htks autos)))
      (else
         (if (hte? fields msg)
            (let ((v (htr fields msg)))
               (if (hte? autos msg)
                  (vaquero-apply v '() 'null cont err) ; exec the thunk
                  (cont v)))
            (if (hte? forwards msg)
               (vaquero-send (htr forwards msg) msg cont err)
               (case msg
                  ((to-text) (cont "object"))
                  ((to-bool) (cont (not (eq? 0 (length (htks fields))))))
                  (else (vaquero-apply (vaquero-obj-default obj) (list msg) 'null cont err))))))))

(define vaquero-send-vtable
   (alist->hash-table
      `((null         . ,vaquero-send-null)
        (bool         . ,vaquero-send-bool)
        (symbol       . ,vaquero-send-symbol)
        (keyword      . ,vaquero-send-symbol)
        (int          . ,vaquero-send-int)
        (real         . ,vaquero-send-real)
        (text         . ,vaquero-send-text)
        (list         . ,vaquero-send-list)
        (pair         . ,vaquero-send-pair)
        (tuple        . ,vaquero-send-tuple)
        (set          . ,vaquero-send-set)
        (primitive    . ,vaquero-send-primitive)
        (vector       . ,vaquero-send-vector)
        (source       . ,vaquero-send-source)
        (sink         . ,vaquero-send-sink)
        (env          . ,vaquero-send-env)
        (table        . ,vaquero-send-table)
        (proc         . ,vaquero-send-proc)
        (object       . ,vaquero-send-object)
        (eof          . ,vaquero-send-EOF)
        (WTF          . ,vaquero-send-wtf))))

