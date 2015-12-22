#lang racket

(require "util.rkt" "ast.rkt")
(provide (all-defined-out))

;; our "runtime", of sorts.
(define (df-union . xs) (set-unions xs))
;; side-effecting funs return the empty tuple, '()
(define (df-puts x) (displayln x) '())
(define (df-print x) (println x) '())
(define ((df= x) y) (equal? x y))
(define ((df+ x) y) (+ x y))
(define ((df- x) y) (- x y))
(define ((df* x) y) (* x y))
(define ((df<= x) y) (<= x y))
(define ((df++ x) y) (string-append x y))
(define ((df-subset? x) y) (subset? x y))
(define (df-max . xs) (if (null? xs) 0 (apply max xs)))
(define (df-or . xs) (ormap identity xs))

;; produces syntax object which evals to an n-ary joiner function for the given
;; type.
;;
;; TODO: this needs optimized.
;;
;; TODO?: use a hashtable mapping types to joiners so that we can generate a
;; joiner for each type *at most once*?
(define (joiner-for t)
  (match t
    [(t-bool) #'df-or]
    [(t-nat) #'df-max]
    [(t-fs _) #'df-union]
    [(or (t-fun i o) (t-mono i o))
     #`(lambda fs (lambda (x) (#,(joiner-for o)
                     (for/list ([f fs]) (f x)))))]
    [(t-tuple ts)
     #`(lambda tuples
         (list #,@(for/list ([i (length ts)] [t ts])
                    #`(apply #,(joiner-for t)
                             (for/list ([x tuples]) (list-ref x #,i))))))]
    [(t-record fs)
     (define (field-expr n t)
       #`(apply #,(joiner-for t) (for/list ([r records]) (hash-ref r '#,n))))
     #`(λ records
         (hash #,@(for*/list ([(n t) fs]
                              [x (list #`'#,n (field-expr n t))])
                    x)))]))