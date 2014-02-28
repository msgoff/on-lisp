(in-package :on-lisp-test)
(in-readtable :on-lisp-test)

(defsuite* test-all)

(defun run-all-tests ()
  (test-all)
  (format t " |~%") ;; needed to avoid screwing up colors in SLIME REPL
  (let ((results
         (run-tests :all :on-lisp-test)))
    (print-errors results)
    (print-failures results)))

(define-test test-blah
  ;; need to have at least one lisp-unit test to not barf in REPL
  (assert-expands
   (blarf)
   (blarf)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 4 - Utility Functions

;; p. 47
(deftest test-filter ()
  (is (equal (filter (lambda (x) (if (numberp x) (1+ x)))
                     #`(a 1 2 b 3 c d 4))
             #`(2 3 4 5))))

;; p. 48
(deftest test-group ()
  (is (equal (group #`(a b c d e f g) 2)
             #`((a b) (c d) (e f) (g)))))

(deftest test-flatten ()
  (is (equal (flatten #`(a (b c) ((d e) f)))
             #`(a b c d e f))))

(deftest test-prune ()
  (is (equal (prune #'evenp #`(1 2 (3 (4 5) 6) 7 8 (9)))
             #`(1 (3 (5)) 7 (9)))))

;; p. 49
(deftest test-before ()
  (is (equal (before 'b 'd #`(a b c d))
             #`(b c d)))
  ;; p. 50
  (is (equal (before 'a 'b #`(a))
             #`(a))))

;; p. 51
(deftest test-after ()
  (is (equal (after 'a 'b #`(b a d))
             #`(a d)))
  (is (null (after 'a 'b #`(a))))
  (is (null (after 'b 'a #`(a)))) ;; I think this is the test pg meant to write
  )

(deftest test-duplicate ()
  (is (equal (duplicate 'a #`(a b c a d))
             #`(a d))))

(deftest test-split-if ()
  (multiple-value-bind (left right)
      (split-if (lambda (x) (> x 4))
                #`(1 2 3 4 5 6 7 8 9 10))
    (is (equal left #`(1 2 3 4)))
    (is (equal right #`(5 6 7 8 9 10)))))

(deftest test-most ()
  (is (equal (most #'length #`((a b) (a b c) (a) (e f g)))
             #`(a b c))))

;; p. 52
(deftest test-best ()
  (is (eql (best #'> #`(1 2 3 4 5)) 5)))

;; p. 53
(deftest test-mostn ()
  (is (equal (mostn #'length #`((a b) (a b c) (a) (e f g)))
             #`((a b c) (e f g)))))

(deftest test-map0-n ()
  (is (equal (map0-n #'1+ 5)
             (copy-list #`(1 2 3 4 5 6)))))

(deftest test-mapa-b ()
  (is (equal (mapa-b #'1+ -2 0 0.5)
             #`(-1 -0.5 0.0 0.5 1.0))))

;; p. 55
(deftest test-rmapcar ()
  (is (equal (rmapcar #'+ #`(1 (2 (3) 4)) #`(10 (20 (30) 40)))
             #`(11 (22 (33) 44)))))

;; p. 58
(deftest test-symb ()
  (let ((s (symb #`(a b))))
    (is (eq s '|(A B)|))
    (is (eq s '\(A\ B\)))))

;; p. 59
(deftest test-explode ()
  (is (equal (explode 'bomb)
             #`(b o m b))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 11 - Classic Macros

;; p. 144
(deftest test-when-bind* ()
  (is (=
       (when-bind* ((x (find-if #'consp #`(a (1 2) b)))
                    (y (find-if #'oddp x)))
         (+ y 10))
       11)))

;; p. 147
(deftest test-condlet ()
  (is (equal
       (condlet (((= 1 2) (x 'a) (y 'b))
                 ((= 1 1) (y 'c) (x 'd))
                 (t (x 'e) (z 'f)))
         (list x y z))
       #`(d c nil))))

;; p. 151
(deftest test-nif ()
  (is (equal
       (mapcar #'(lambda (x)
                   (nif x 'p 'z 'n))
               #`(0 1 -1))
       #`(z p n))))

;; p. 163
#+sbcl
(define-test test-mvdo
  (assert-expands
   (LET (#:G2 #:G3 #:G4)
     (MVPSETQ #:G2 1 (#:G3 #:G4) (VALUES 0 0))
     (PROG ((X #:G2) (Y #:G3) (Z #:G4))
        #:G1
        (IF (> X 5)
            (RETURN (PROGN (LIST X Y Z))))
        (PRINC (LIST X Y Z))
        (MVPSETQ X (1+ X) (Y Z) (VALUES Z X))
        (GO #:G1)))
   (mvdo ((x 1 (1+ x))
          ((y z) (values 0 0) (values z x)))
       ((> x 5) (list x y z)) (princ (list x y z)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 12 - Generalized Variables

;; p. 168
(deftest test-toggle ()
  (is (equal
       (let ((lst #`(t nil t)) (i -1))
         (toggle (nth (incf i) lst))
         lst)
       #`(nil nil t))))

;; p. 174
(deftest test-pull ()
  (let ((x (copy-tree #`(1 2 (a b) 3))))
    (is (equal (pull 2 x)
               #`(1 (a b) 3)))
    (is (equal (pull #`(a b) x :test #'equal)
               #`(1 3)))
    (is (equal x
               #`(1 3)))))

;; p. 175
(deftest test-pull-if ()
  (let ((lst #`(1 2 3 4 5 6)))
    (pull-if #'oddp lst)
    (is (equal lst
               #`(2 4 6)))))

(deftest test-popn ()
  (let ((x #`(a b c d e f)))
    (is (equal (popn 3 x)
               #`(a b c)))
    (is (equal x
               #`(d e f)))))

(deftest test-sortf ()
  (let ((x 1)
        (y 2)
        (z 3))
    ;; In the text, this returns 3 but by looking at the expansion it should
    ;; clearly return 1. I'm guessing pg produced the output with an earlier
    ;; draft version of the macro.
    (is (equal (sortf > x y z)
               1)) 
    (is (equal (list x y z)
               #`(3 2 1)))))

;; p. 178
(deftest test-_f ()
  (let ((x 2))
    (_f nif x 'p 'z 'n)
    (is (eq x 'p))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 13 - Computation at Compile-Time

;;p. 182
#+sbcl
(define-test test-most-of
  (assert-expands
   (LET ((#:G1 0))
     (OR (AND (A) (> (INCF #:G1) 1)) (AND (B) (> (INCF #:G1) 1))
         (AND (C) (> (INCF #:G1) 1))))
   (most-of (a) (b) (c))))

;; p. 185
#+sbcl
(define-test test-nthmost
  (assert-expands
   (LET ((#:G1 NUMS))
     (UNLESS (< (LENGTH #:G1) 3)
       (LET ((#:G8 (POP #:G1)))
         (SETQ #:G3 #:G8))
       (LET ((#:G7 (POP #:G1)))
         (IF (> #:G7 #:G3)
             (SETQ #:G4 #:G3
                   #:G3 #:G7)
             (SETQ #:G4 #:G7)))
       (LET ((#:G6 (POP #:G1)))
         (IF (> #:G6 #:G3)
             (SETQ #:G5 #:G4
                   #:G4 #:G3
                   #:G3 #:G6)
             (IF (> #:G6 #:G4)
                 (SETQ #:G5 #:G4
                       #:G4 #:G6)
                 (SETQ #:G5 #:G6))))
       (DOLIST (#:G2 #:G1)
         (IF (> #:G2 #:G3)
             (SETQ #:G5 #:G4
                   #:G4 #:G3
                   #:G3 #:G2)
             (IF (> #:G2 #:G4)
                 (SETQ #:G5 #:G4
                       #:G4 #:G2)
                 (IF (> #:G2 #:G5)
                     (SETQ #:G5 #:G2)
                     NIL))))
       #:G5))
   (nthmost 2 nums)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 15 - Macros Returning Functions

;; p. 203
(deftest test-fn ()
  (is (equal (mapcar (fn (and integerp oddp)) #`(c 3 p 0))
             #`(nil t nil nil)))
  (is (equal (mapcar (fn (or integerp symbolp)) #`(c 3 p 0.2))
             #`(t t t nil)))
  (is (equal (map1-n (fn (if oddp 1+ identity)) 6)
             #`(2 2 4 4 6 6)))
  (is (equal (mapcar (fn (list 1- identity 1+))
                     #`(1 2 3))
             #`((0 1 2) (1 2 3) (2 3 4))))
  (is (equal (remove-if (fn (or (and integerp oddp)
                                (and consp cdr)))
                        #`(1 (a b) c (d) 2 3.4 (e f g)))
             #`(c (d) 2 3.4))))

;; p. 206
(deftest test-unions ()
  ;; ordering not predictable in general, but whatever
  (is (equal (unions #`(a b) #`(b c) #`(c d))
             #`(a d b c))))

;; p. 207
(deftest test-differences ()
  (is (equal (differences #`(a b c d e) #`(a f) #`(d))
             #`(b c e))))

(deftest test-maxmin ()
  (is (equal (multiple-value-bind
                   (max min) (maxmin #`(3 4 2 8 5 1 6 7))
               (list max min))
             #`(8 1))))

;; p. 211
(deftest test-delay-force ()
  (is (eq (force 'a) 'a))
  (let ((d (delay (1+ 2))))
    (is (= (force d) 3))
    (is (= (force d) 3))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 16 - Macro-Defining Macros

;; p. 219
(defun mass-cost (menu-price)
    (a+ menu-price (* it .05) (* it 3)))

(deftest test-a+ ()
  (is (= (mass-cost 7.95)
         9.54)))

(deftest test-alist ()
  (is (equal (alist 1 (+ 2 it) (+ 2 it))
             #`(1 3 5))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 17 - Read-Macros

;; p. 226
(deftest test-#? ()
  (is (equal (mapcar #?2 #`(a b c))
             #`(2 2 2)))
  ;; p. 227
  (is (eq (funcall #?'a) 'a))
  (is (eq (funcall #?#'oddp) (symbol-function 'oddp))))


(deftest test-sharp-brackets ()
  (is (equal #[2 7]
             #`(2 3 4 5 6 7))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 18 - Destructuring

;; p. 231
(deftest test-dbind ()
  (is (equal (dbind (a b c) #(1 2 3) (list a b c))
             #`(1 2 3)))
  (is (equal (dbind (a (b c) d) #`(1 #(2 3) 4) (list a b c d))
             #`(1 2 3 4)))
  (is (equal (dbind (a (b . c) &rest d) #`(1 "fribble" 2 3 4) (list a b c d))
             #`(1 #\f "ribble" (2 3 4)))))

;; p. 233
(deftest test-destruc ()
  (is (equal (destruc #`(a b c) 'seq #'atom)
             #`((a (elt seq 0)) (b (elt seq 1)) (c (elt seq 2))))))


(defmacro destruc-macro (pat seq)
  (destruc pat seq))

(define-test test-destruc-expand
  (assert-expands
   ((A (ELT SEQ 0))
    ((#:G1 (ELT SEQ 1))
     (B (ELT #:G1 0))
     (C (SUBSEQ #:G1 1)))
    (D (SUBSEQ SEQ 2)))
   (destruc-macro (a (b . c) &rest d) seq)))

(defmacro dbind-ex-macro (binds body)
  (dbind-ex binds body))

(define-test test-dbind-ex-expand
  (assert-expands
   (LET ((A (ELT SEQ 0))
         (#:G1 (ELT SEQ 1))
         (D (SUBSEQ SEQ 2)))
     (LET ((B (ELT #:G1 0))
           (C (SUBSEQ #:G1 1)))
       (PROGN BODY)))
   (dbind-ex-macro
    ((A (ELT SEQ 0))
     ((#:G1 (ELT SEQ 1))
      (B (ELT #:G1 0))
      (C (SUBSEQ #:G1 1)))
     (D (SUBSEQ SEQ 2)))
    (body))))

;; p. 235
(let ((ar (make-array #`(3 3))))
  (deftest test-with-matrix ()
    (for (r 0 2)
      (for (c 0 2)
        (setf (aref ar r c) (+ (* r 10) c))))
    (is (equal (with-matrix ((a b c)
                             (d e f)
                             (g h i)) ar
                 (list a b c d e f g h i))
               #`(0 1 2 10 11 12 20 21 22))))
  (deftest test-with-array ()
    (is (equal (with-array ((a 0 0) (d 1 1) (i 2 2)) ar
                 (list a d i))
               #`(0 11 22)))))

;; p. 236
(deftest test-with-struct ()
  (defstruct visitor name title firm)
  (let ((theo
         (make-visitor :name "Theodebert"
                       :title 'king
                       :firm 'franks)))
    (is (equal (with-struct (visitor- name firm title) theo
                 (list name firm title))
               #`("Theodebert" franks king)))))

(deftest test-with-places ()
  (is (equal (with-places (a b c) #(1 2 3)
               (list a b c))
             #`(1 2 3)))
  ;; p. 237
  (is (equal
       (let ((lst #`(1 (2 3) 4)))
         (with-places (a (b . c) d) lst
           (setf a 'uno)
           (setf c '(tre)))
         lst)
       #`(uno (2 tre) 4))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 19 - A Query Compiler



;; p. 252
(clear-db)
(fact painter hogarth william english)
(fact painter canale antonio venetian)
(fact painter reynolds joshua english)
(fact dates hogarth 1697 1772)
(fact dates canale 1697 1768)
(fact dates reynolds 1723 1792)

;; p. 253
#+nil
(deftest hogarth% ()
  (let ((answers))
    (with-answer% (painter hogarth ?x ?y)
      (push (list ?x ?y) answers))
    (is (= (length answers) 1))
    (is (member #`(william english) answers :test #'equal))))
#+nil
(deftest born-1697% ()
  (let ((answers))
    (with-answer% (and (painter ?x _ _)
                       (dates ?x 1697 _))
      (push (list ?x) answers))
    (is (= (length answers) 2))
    (is (member #`(canale) answers :test #'equal))
    (is (member #`(hogarth) answers :test #'equal))))
#+nil
(deftest died-1772-or-1792% ()
  (let ((answers))
    (with-answer% (or (dates ?x ?y 1772)
                      (dates ?x ?y 1792))
      (push (list ?x ?y) answers))
    (is (= (length answers) 2))
    (is (member #`(hogarth 1697) answers :test #'equal))
    (is (member #`(reynolds 1723) answers :test #'equal))))
#+nil
(deftest not-shared-birth-year% ()
  (let ((answers))
    (with-answer% (and (painter ?x _ english)
                       (dates ?x ?b _)
                       (not (and (painter ?x2 _ venetian)
                                 (dates ?x2 ?b _))))
      (push (list ?x) answers))
    (is (equal answers #`((reynolds))))))


;; p. 257
#+nil
(deftest hogarth ()
  (let ((answers))
    (with-answer (painter 'hogarth ?x ?y)
      (push (list ?x ?y) answers))
    (is (= (length answers) 1))
    (is (member #`(william english) answers :test #'equal))))
#+nil
(deftest not-shared-birth-year ()
  (let ((answers))
    (with-answer (and (painter ?x _ 'english)
                      (dates ?x ?b _)
                      (not (and (painter ?x2 _ 'venetian)
                                (dates ?x2 ?b _))))
      (push (list ?x) answers)
      (is (equal answers #`((reynolds)))))))
#+nil
(deftest died-1770-to-1800 ()
  (let ((answers))
    (with-answer (and (painter ?x _ _)
                      (dates ?x _ ?d)
                      (lisp (< 1770 ?d 1800)))
      (push (list ?x ?d) answers)
      (is (= (length answers) 2))
      (is (member #`(reynolds 1792) answers :test #'equal))
      (is (member #`(hogarth 1772) answers :test #'equal)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 20 - Continuations

;; p. 268
(=defun message ()
  (=values 'hello 'there))

;; p. 269
(=defun baz ()
  (=bind (m n) (message)
    (=values (list m n))))

(deftest cont-test ()
  (is (equal (baz) #`(hello there))))

;; p. 271
(deftest dft-test ()
  (setq t1 #`(a (b (d h)) (c e (f i) g))
        t2 #`(1 (2 (3 6 7) 4 5)))
  ;;(dft2 t1)
  )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 21 - Multiple Processes

;; p. 282
(defvar *bboard* nil)

(defun claim (&rest f) (push f *bboard*))

(defun unclaim (&rest f) (pull f *bboard* :test #'equal))

(defun check (&rest f) (find f *bboard* :test #'equal))

(=defun visitor (door)
  (format t "Approach ~A. " door)
  (claim 'knock door)
  (wait d (check 'open door)
    (format t "Enter ~A. " door)
    (unclaim 'knock door)
    (claim 'inside door)))

(=defun host (door)
  (wait k (check 'knock door)
    (format t "Open ~A. " door)
    (claim 'open door)
    (wait g (check 'inside door)
      (format t "Close ~A.~%" door)
      (unclaim 'open door))))

(program ballet ()
  (fork (visitor 'door1) 1)
  (fork (host 'door1) 1)
  (fork (visitor 'door2) 1)
  (fork (host 'door2) 1))

(deftest ballet-test ()
  ;;(ballet)
  nil)

;; p. 283
(=defun capture (city)
  (take city)
  (setpri 1)
  (yield
    (fortify city)))

(=defun plunder (city)
  (loot city)
  (ransom city))

(defun take (c) (format t "Liberating ~A.~%" c))
(defun fortify (c) (format t "Rebuilding ~A.~%" c))
(defun loot (c) (format t "Nationalizing ~A.~%" c))
(defun ransom (c) (format t "Refinancing ~A.~%" c))

(program barbarians ()
  (fork (capture 'rome) 100)
  (fork (plunder 'rome) 98))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 22 - Nondeterminism

;; p. 297
(=defun two-numbers ()
  (choose-bind n1 '(0 1 2 3 4 5)
    (choose-bind n2 '(0 1 2 3 4 5)
      (=values n1 n2))))

(=defun parlor-trick (sum)
  (=bind (n1 n2) (two-numbers)
    (if (= (+ n1 n2) sum)
        `(the sum of ,n1 ,n2)
        (fail))))

(deftest parlor-trick-test ()
  (is (equal (parlor-trick 7)
             #`(the sum of 2 5))))
;; p. 299
(=defun descent (n1 n2)
  (cond ((eq n1 n2) (=values (list n2)))
        ((kids n1) (choose-bind n (kids n1)
                     (=bind (p) (descent n n2)
                       (=values (cons n1 p)))))
        (t (fail))))

(defun kids (n)
  (case n
    (a #`(b c))
    (b #`(d e))
    (c #`(d f))
    (f #`(g))))

(deftest descent-test ()
  (is (equal (descent 'a 'g)
             #`(a c f g))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Chapter 23 - An ATN Compiler
(def-atn-node s
    (down np s/subj
          (setr mood 'decl))
  (cat v v
       (setr mood 'imp)
       (setr subj '(np (pron you)))
       (setr aux nil)
       (setr v *)))
