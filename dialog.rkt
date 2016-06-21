#lang racket
(require racket/generator)
(require racket/string)

(require "system.rkt")
(provide toggle-todos add-todo)

; takes a list of (tag item status)s
; returns the new state of the todo list after toggling
(define toggle-todos
  (lambda (todo-list)
    (let* ([menu-heigth (number->string (length todo-list))]
           [window-options (list "--title" "YATΛ!" "--checklist" "Toggle Todos" WINDOW-HEIGHT WINDOW-WIDTH menu-heigth)]
           [todo-list-options (todo-list->shell-options todo-list)]
           [arguments (append window-options todo-list-options)])

      (map cdr ; removes the index again
           ; TODO: refactor
           (apply-status ; returns todo-list with completed field true or false based on the complted indices list
            (zip-with-index (sort todo-list #:key caddr <) 1)
            (map string->number
                 (string-split ; "1 3 4" -> '("1" "3" "4")
                  (dialog->string arguments)))))))) ; returns the indices of the checked todos




(define add-todo (lambda ()
                  (let ([add-todo-text-options (list "--clear" "--title" "YATΛ!" "--inputbox" "New Todo: Content" WINDOW-HEIGHT WINDOW-WIDTH)]
                        [add-todo-priority-options (list "--clear" "--title" "YATΛ!" "--menu" "New Todo: Priority" WINDOW-HEIGHT WINDOW-WIDTH "3" "1" "High" "2" "Medium" "3" "Low")])
                    (define text (dialog->string add-todo-text-options))
                    (define priority (string->number(dialog->string add-todo-priority-options)))
                    (list text #f priority))))

; returns todo-list with completed field true or false based on the complted indices list
(define apply-status
(lambda (todo-list completed-indices)
  ; map over todo itmes
  (map (lambda (todo-item)
         ; if the todo item's index is member of the completed indicies
         (cond [(member (string->number(car todo-item)) completed-indices)
                ; set it's completed status to true
                (list-set todo-item 2 #t)]
               [else
                (list-set todo-item 2 #f)]))
       todo-list)))

; to todo-list->shell-options -> sanitize to use as argument. ex: #f to OFF
(define argify-status (lambda (todo) (if (cadr todo)
                         (cons (car todo) "ON")
                         (cons (car todo) "OFF"))))

; TODO: refactor todo-list->shell-options to operate on single todo-item and call map in todo-list
; returns a whiptail/dialog compatible arguemnt string from a todo-list
; ("1st todo" #f 4) -> "1" "1st todo" "OFF"
(define todo-list->shell-options (lambda (todo-list)
                (flatten
                 (zip-with-index
                  ; replace #t and #f with ON and OFF
                  (map argify-status
                       (map (lambda (todo-item)
                              ; only take title and completed field
                              (take todo-item 2))
                            ; sort by priority
                            (sort todo-list #:key caddr <)))
                  1))))

; (zip-with-index '("@" "!" "%") 3) -> '(3 . "@") (4 . "!") (5 . "%"))
(define zip-with-index (lambda (lst start-index)
                         ; define a generators of natural integers starting from start-index
                         (letrec ([naturals (sequence->generator (in-naturals start-index))]
                                  [zip-with-naturals (lambda (lst)
                                                       (cond ((empty? lst) empty)
                                                             (else (cons
                                                                    ; cons (1 "a")
                                                                    (cons
                                                                          (number->string(naturals))
                                                                          (car lst))
                                                                    ; with the recursive call on the lst's tail
                                                                    (zip-with-naturals(cdr lst))))))])
                           (zip-with-naturals lst))))