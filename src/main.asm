; Read each file and lign it's content to the left
; Example:
;  Input:
;   file1.txt:
;   123
;   12
;   1
;  Output:
;   |123|
;   | 12|
;   |  1|
; Usage: ./program <filename1>

; From ioutils
extern open_file, read_file, write_file, close_file, seek_file, write_stdout 

; From argsutils
extern init_args, get_argc, get_argv, get_arg

; From strutils
extern strlen, strcmp

global _start

; Constants
BUFFER_SIZE equ 100

; Open flags
O_RDONLY equ 0
O_WRONLY equ 1

; Seek flags
SEEK_SET equ 0
SEEK_CUR equ 1
SEEK_END equ 2

section .rodata
    nl db 0xa, 0    ; New line
    nl_len equ $-nl ; New line length

    usage_msg db 'Usage: ./program <filename1>', 0xa, 0
    usage_msg_len equ $-usage_msg

    error_msg db 'Error', 0xa, 0
    error_msg_len equ $-error_msg

    error_maybe_forgor_return db 'ERROR!! Maybe you forgot to return', 0xa, 0
    error_maybe_forgor_return_len equ $-error_maybe_forgor_return


section .data
    buffer db BUFFER_SIZE dup(0)
    buffer_len equ $-buffer

section .text
_start:
    ; Read the arguments
    mov rdi, [rsp] 
    lea rsi, [rsp + 8] 
    call init_args 

    ; Check if there is only one file
    call get_argc
    cmp rax, 2
    jne no_files_exit

    ; Get the file name
    mov rsi, 1
    call get_arg

    ; Process the file
    mov rdi, rax
    call process_file

    ; Exit the program
    jmp ok_exit

; Process File
; ## Input:
;   - rdi: File name
; ## Output:
;   - rax: 0 if the file was processed
;          -1 if the file was not processed
process_file:
    ; Open the file
    mov rdi, rdi
    mov rsi, O_RDONLY
    xor rdx, rdx
    call open_file
    push rax

    ; Check if the file was opened
    cmp rax, 0
    jl error_exit

    ; Get the max line length
    mov rdi, rax
    call get_max_line_length

    _after_get_max_line_length:

    ; Close the file
    pop rdi
    call close_file

    ret


; Get Max Line Length
; ## Input:
;   - rdi: file descriptor
; ## Output:
;   - rax: Max line length
get_max_line_length:
    xor r8, r8 ; Buffer length
    xor r9, r9 ; Max line length
    xor r10, r10 ; Current line length
    xor r11, r11 ; Current character

    .read_file_loop:
        ; Read the file
        mov rdi, rdi
        lea rsi, [buffer]
        mov rdx, BUFFER_SIZE
        call read_file

        ; Check if the file was read
        cmp rax, 0
        jle .get_max_line_length_exit

        ; Loop through the buffer
        mov r8, rax
        mov rsi, buffer
        .loop_through_buffer:
            ; Check if the buffer is empty
            cmp r8, 0
            je .read_file_loop

            ; Get the character
            mov r11, rsi
            inc rsi
            dec r8

            ; Check if the character is a new line
            cmp byte [r11], 0xa
            je .new_line

            ; Increment the current line length
            inc r10
            jmp .loop_through_buffer

            .new_line:
                ; Check if the current line length is greater than the max line length
                mov rax, r10
                xor r10, r10

                cmp rax, r9
                jle .loop_through_buffer

                ; Set the max line length
                mov r9, rax
                jmp .loop_through_buffer

        ; Loop through the file
        jmp .read_file_loop
    
    .get_max_line_length_exit:
    ; Seek 0
    mov rdi, rdi
    mov rsi, 0
    mov rdx, SEEK_SET
    call seek_file

    mov rax, r9
    ret


; Exit the program with an error message
segfault_exit:
    mov rsi, error_maybe_forgor_return
    mov rdx, error_maybe_forgor_return_len
    call write_stdout

    mov rax, rax
    mov rax, [rax]


; Exit the program
ok_exit:
    mov rax, 60
    xor edi, edi
    syscall

; Exit the program with an usage message
no_files_exit:
    mov rsi, usage_msg
    mov rdx, usage_msg_len
    call write_stdout

    mov rax, 60
    mov edi, 1
    syscall

; Exit the program with an error message
error_exit:
    mov rsi, error_msg
    mov rdx, error_msg_len
    call write_stdout

    mov rax, 60
    mov edi, 1
    syscall
