; Args utils
; This file provides a set of utilities for working with the program Args.

global init_args, get_argc, get_argv, get_arg

QWORD_SIZE equ 8

section .data
    argc dq 0 ; size_t argc -- Number of arguments
    argv dq 0 ; char[][] argv -- Arguments vector 


section .text

; Set Argc, Argv
; ## Input:
; rdi -- argc
; rsi -- char[][] argv
; ## Output:
; <None>
init_args:
    mov [argc], rdi  ; Store argc
    mov [argv], rsi  ; Store argv
    ret

; Get the number of arguments
; ## Input:
; <None>
; ## Output:
; rax -- Number of arguments
get_argc:
    mov rax, [argc]
    ret

; Get the arguments vector
; ## Input:
; <None>
; ## Output:
; rax -- char[][] Arguments vector
get_argv:
    mov rax, [argv]
    ret

; Get the argument at the specified index
; ## Input:
; rsi -- Index of the argument
; ## Output:
; rax -- char[] Argument at the specified index
get_arg:
    call get_argv
    mov rax, [rax + rsi * QWORD_SIZE]
    ret
