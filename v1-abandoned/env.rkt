#lang racket

;; I don't need this yet, because I don't allow binding type names.

(require "util.rkt" "types.rkt")
(provide (all-defined-out))

;; An env maps expression variables to info about them, and type names to their
;; (fully substituted) definitions. An env is agnostic wrt the info it carries
;; about expression variables - in a typed language, it would be a parameterized
;; type.
(define-struct/contract env
  ([vars (hash/c symbol? any/c #:immutable #t)]
   [types (hash/c symbol? exact-type? #:immutable #t)])
  #:transparent)

(define empty-env (env (hash) (hash)))

;; variable operations
(define (env-ref-var e n [orelse (lambda () (error "unbound variable:" n))])
  (hash-ref (env-vars e) n orelse))
(define (env-bind-var name info e)
  (env (hash-set (env-vars e) name info) (env-types e)))
(define/contract (env-bind-vars h e)
  ((hash/c symbol? any/c) env? . -> . env?)
  (env (hash-union-right (env-vars e) h) (env-types e)))
(define (env-map-vars f e)
  (env (hash-map-vals f (env-vars e)) (env-types e)))

;; type operations
(define (env-ref-type e n [orelse (lambda () (error "undefined type:" n))])
  (hash-ref (env-types e) n orelse))
(define (env-bind-type name type e)
  ;; we substitute the type to ensure that envs never contain non-type-wf? types
  (env (env-vars e) (hash-set (env-types e) name (env-subst-type e type))))

(define/contract (env-subst-type e t [orelse (lambda (n) (error "undefined type:" n))])
  (->* (env? exact-type?) ((-> symbol? any)) exact-type?)
  (type-fold t
    (match-lambda
      [`(var ,n) (env-ref-type e n (lambda () (orelse n)))]
      [x x])))
