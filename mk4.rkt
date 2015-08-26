#lang racket

(provide run run*
         == =/=
         fresh
         conde
         symbolo numbero
         absento
         (all-defined-out))

;; extra stuff for racket
;; due mostly to samth
(define (list-sort f l) (sort l f))

(define (remp f l) (filter-not f l))

(define (call-with-string-output-port f)
  (define p (open-output-string))
  (f p)
  (get-output-string p))

(define (exists f l) (ormap f l))

(define for-all andmap)

(define (find f l)
  (cond [(memf f l) => car] [else #f]))

(define memp memf)

(define (var*? v) (var? (car v)))


; Substitution representation

(define empty-subst-map (hasheq))

(define subst-map-length hash-count)

; Returns #f if not found, or a pair of u and the result of the lookup.
; This distinguishes between #f indicating absence and being the result.
(define subst-map-lookup
  (lambda (u S)
    (hash-ref S u unbound)))

(define (subst-map-add S var val)
  (hash-set S var val))

(define subst-map-eq? eq?)


; Constraint store representation

(define empty-C (hasheq))

(define set-c
  (lambda (v c st)
    (state (state-S st) (hash-set (state-C st) v c))))

(define lookup-c
  (lambda (v st)
    (hash-ref (state-C st) v empty-c)))

(define remove-c
  (lambda (v st)
    (state (state-S st) (hash-remove (state-C st) v))))


(include "mk.scm")

(define appendo
  (λ (l s ls)
    (conde
     [(== '() l) (== ls s)]
     [(fresh (first rest result)
             (== (cons first rest) l)
             (== (cons first result) ls)
             (appendo rest s result)
             )])))

;;(run 2 (q) (appendo '(a b c) '(d e) q))

(define peanoo
  (λ (n)
    (conde
     [(== 'z n)]
     [(fresh (m)
      (== `(s ,m) n)
      (peanoo m))])))

(define pluso
  (λ (x n o)
    (conde
     [(== x 'z) (== o n)]
     [(fresh (px res)
             (== x `(s ,px))
             (== `(s ,res) o)
             (pluso px n res))])))

;(run 1 (q) (pluso `(s (s z)) `(s (s z)) q))

(define subo
  (λ (x y o)
    (pluso y o x)))

;(run* (q) (subo `(s (s z)) `(s z) q))

(define equalso
  (λ (x y)
    (subo x y 'z)))

(define lesso
  (λ (x y)
    (fresh (res)
           (=/= res 'z)
           (subo y x res))))
     

;(run 1 (q) (lesso `(s z) `(s (s z))))
;(run 1 (q) (lesso `(s z) `(s z)))
;(run 1 (q) (subo `(s (s z)) `(s z) q))
;(run 1 (q) (=/= '(s z) 'z))

(define rembero
  (λ (e l out)
    (conde
      [(== '() l) (== '() out)]
      [(== (cons e out) l)]
      [(fresh (first rest result)
              (=/= first e)
              (== (cons first rest) l)
              (== (cons first result) out)
              (rembero e rest result))])))


;;(run 2 (q) (rembero q '(x y f g) '(x y f g)))

(define one-item
  (lambda (x s)
    (cond
      [(null? s) '()]
      [else (cons (cons x (car s))
              (one-item x (cdr s)))])))

(define one-itemo
  (λ (x s xs)
    (conde
     [(== s '()) (== xs '())]
     [(fresh (first rest result)
             (== (cons first rest) s)
             (== (cons (cons x first) result) xs)
             (one-itemo x rest result))])))

(define assqo
  (lambda (x ls out)
    (fresh (h t th tt)
           (=/= ls '())
           (== (cons h t) ls)
           (conde
            [ (== (cons th tt) h)
              (== th x)
              (== h out)]
            [(assqo x t out)]))))

(define multi-rembero
  (lambda (e l out)
    (conde
      [(== l '()) (== out '())]
      [(fresh (first rest result)
              (== (cons first rest) l)
             (conde
              [(== first e) (multi-rembero e rest out)]
              [(=/= first e) (== (cons first result) out)
               (multi-rembero e rest result)]))])))

;(run* (x y)
;     (conde
;      [(== 0 1) (== x 5) (== 'a y)]
;      [(== x 6) (=='b y)]
;      [(== x 7) (== 'c y)]))

(define !-o
  (λ (gamma expr type)
    (conde
     [(!-varo gamma expr type)]
     [(!-lambdao gamma expr type)]
     [(!-zeroo gamma expr type)]
     [(!-ifo gamma expr type)]
     [(!-appo gamma expr type)])))

(define !-varo
  (λ (gamma x type)
    (fresh ()
           (symbolo x)
           (gamma-lookupo gamma x type))))

(define gamma-lookupo
        (lambda (gamma x type)
                (conde
                        [(fresh (rest)
                                (== `((,x . ,type) . ,rest) gamma))]
                        [(fresh (y t rest)
                                (== `((,y . ,t) . ,rest) gamma)
                                (=/= y x)
                                (gamma-lookupo rest x type))])))

(define !-lambdao
  (λ (gamma expr type)
    (fresh (T1 T2 x e)
           (== `(lambda (,x) ,e) expr)
           (== `(,T1 -> ,T2) type)
           (symbolo x)
           (!-o `((,x . ,T1) . ,gamma) e T2))))

(define !-zeroo
  (λ (gamma expr type)
    (fresh (e)
           (== `(zero? ,e) expr)
           (== 'bool type)
           (!-o gamma e 'int))))

(define !-ifo
  (λ (gamma expr type)
    (fresh (e1 e2 e3)
           (== `(if ,e1 ,e2 ,e3) expr)
           (!-o gamma e1 'bool)
           (!-o gamma e2 type)
           (!-o gamma e3 type))))

(define !-appo
  (λ (gamma expr T)
    (fresh (T1 e1 e2)
            (== `(,e1 ,e2) expr)
            (!-o gamma e1 `(,T1 -> ,T))
            (!-o gamma e2 T1))))


(define S1
  (λ (str)
    (conde
      [(== str '())]
      [(fresh (h t)
              (== (cons h t) str)
              (conde
               [(== h 0) (S2 t)]
               [(== h 1) (S1 t)]))])))

(define S2
  (λ (str)
    (fresh (h t)
           (=/= str '())
           (== (cons h t) str)
           (conde
               [(== h 0) (S1 t)]
               [(== h 1) (S2 t)]))))

(define reverseo
  (λ (lst rev)
    (conde
     [(== lst '()) (== rev '())]
     [(fresh (h t res)
       (== (cons h t) lst)
       (== (cons )))])))

(define palindromeo
  (λ (x)
    (reverseo x x)))

(define Z
  (λ (f)
    ((λ (x) (f (λ (n) ((x x) n))))
     (λ (x) (f (λ (n) ((x x) n)))))))

 ; (run* (q) (reverseo '(a b c) q)) => '((c b a))


;(run 30 (q) (S1 q))
;(run* (q)
;      (fresh (t)
;          (!-o '((y . int))
;           '(lambda (x) (if (zero? x) y y))
;           q)))

(define run-keyword
  (λ (keyword expr env out)
    (conde
     [(== keyword 'quote)
      (== out expr)]
     [(fresh (res)
              (== keyword 'null?)
              (eval-expro expr env res)
              (== out (null? res)))]
     
     [(fresh (e1 e2 e3 condition)
             (== keyword 'if)
             (== expr `(,e1 ,e2 ,e3))
             (eval-expro e1 env condition)
             (conde
              [(== condition #t) (eval-expro e2 env out)]
              [(== condition #f) (eval-expro e3 env out)]))])))

(define eval-expro
  (λ (expr env out)
    (conde
      [(numbero expr) (== out expr)]
;      [(stringo expr) (== out expr)]
      [(== expr #t) (== out #t)]
      [(== expr #f) (== out #f)]
;      [`(cons ,e1 ,e2) (cons (eval-expr e1 env) (eval-expr e2 env))]
;      [`(car ,e) (car (eval-expr e env))]
;      [`(cdr ,e) (cdr (eval-expr e env))]

      [(symbolo expr) (lookupo expr env out)] ;variables

      [(fresh (x body)
              (== expr `(lambda (,x) ,body))
              (== out `(closure ,x ,body ,env)))] ; lambda 

      [(fresh (e1 e2 proc arg x body env^)
              (== expr `(,e1 ,e2))
              (conde
               [(lookupo e1 env '_keyword) (run-keyword e1 e2 env out)]
               [(eval-expro e1 env proc)
                (eval-expro e2 env arg)
                (conde
                 [(== proc `(closure ,x ,body ,env^))
                  (eval-expro body `((,x . ,arg) . ,env^) out)])]
               ))])))
    
(define lookupo
  (λ (x env out)
    (fresh (y v rest)
           (== env `((,y . ,v) .,rest))
           (conde
            [(== x y) (== out v)]
            [(=/= x y) (lookupo x rest out)])
           )))


(run* (q) (eval-expro 'y '((y . #t) (x . #f) (if . _keyword) (null? . _keyword) (quote . _keyword)) q))
(run* (q) (eval-expro '(quote (a b c)) '((if . _keyword) (null? . _keyword) (quote . _keyword)) q))
(run* (q) (eval-expro '(if #t 1 0) '((if . _keyword) (null? . _keyword) (quote . _keyword)) q))
(run* (q) (eval-expro '(((lambda (x) 5) 3)) '((if . _keyword) (null? . _keyword) (quote . _keyword)) q))

;(run* (q) (lookupo 'if '((if . _keyword) (null? . _keyword) (quote . _keyword)) q))
(run 1 (q) (fresh (e) (== '(if #t 1 0) `(,q . ,e)) (== q 'if)))

(run 1 (q) (eval-expro
 '(((lambda (f)
      ((lambda (x) (f (lambda (n) ((x x) n))))
       (lambda (x) (f (lambda (n) ((x x) n))))))
    (lambda (!)
      (lambda (n)
        (if (zero? n)
            1
            (* (! (sub1 n)) n)))))
   5)
 '()
 q))

;((Z (λ (!)
;      (λ (n)
;        (if (zero? n)
;            1
;            (* (! (sub1 n)) n)
;            )))) 5)
