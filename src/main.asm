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

; Include macro.asm
%include 'src/macro.asm'

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

    zero db 0


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
;   None
process_file:
    ; Open the file
    mov rdi, rdi
    mov rsi, O_RDONLY
    xor rdx, rdx
    call open_file
    push rax ; Save the file descriptor

    ; Check if the file was opened
    cmp rax, 0
    jl error_exit

    ; Get the max line length
    pop rdi
    push rdi ; Save the file descriptor
    call get_max_line_length

    ; Seek 0
    pop rdi
    push rdi ; Save the file descriptor
    mov rdi, rdi
    mov rsi, 0
    mov rdx, SEEK_SET
    call seek_file

    ; Display the lines
    pop rdi
    push rdi ; Save the file descriptor
    call display_numbers
    _after_display_numbers:

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
    clear_reg r8 ; Buffer length
    clear_reg r9 ; Max line length
    clear_reg r10 ; Current line length
    clear_reg r11 ; Current character

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

            ; Using cmovg to avoid branching
            ; max_length = length > max_length ? length : max_length;
            cmp r10, r9 ; Check if the current line length is greater than the max line length
            cmovg r9, r10 ; Set the max line length

            ; length = length + 1;
            inc r10

            ; length = (buffer[i] == '\n') ? 0 : length;
            mov rax, 0 ; TODO: use zero
            cmp byte [r11], 0xa ; Check if the character is a new line
            cmove r10, rax ; Set the current line length to 0 if the character is a new line
            
            ; Loop through the buffer
            jmp .loop_through_buffer

        ; Loop through the file
        jmp .read_file_loop
    
    .get_max_line_length_exit:

    mov rax, r9
    ret


; Display Lines
; Steps:
; - Get the length of the next line
; - If length is -1, return
; - Read the line from the file
; - repeat ' ' max_length - length times
; - Write the line to stdout
; - Repeat
display_numbers:
    call get_next_line_length
    ret


; Get the length of the next line in a file and seek back
; ## Input:
;   - rdi: file descriptor
; ## Output:
;   - rax: length of the next line (line length + new line length)
get_next_line_length:
    clear_reg r8 ; Buffer length
    clear_reg r9 ; Seekback
    clear_reg r10 ; Length
    clear_reg r11 ; Current character

    .read_file_loop:
        ; Read the file
        mov rdi, rdi
        lea rsi, [buffer]
        mov rdx, BUFFER_SIZE
        call read_file

        ; Check if the file was read
        cmp rax, 0
        je .get_next_line_length_exit

        ; Add the bytes read to the seekback
        add r9, rax

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

            ; length = length + 1;
            inc r10

            cmp byte [r11], 0xa ; Check if the character is a new line
            jne .loop_through_buffer

            ; Return the length
            jmp .get_next_line_length_exit

        ; Loop through the buffer
        jmp .loop_through_buffer

    .get_next_line_length_exit:
        ; seek back
        mov rdi, rdi
        mov rsi, r9
        neg rsi
        mov rdx, SEEK_CUR 
        call seek_file

        cmp r10, 0
        je .get_next_line_length_exit_error
        jmp .get_next_line_length_exit_ok

    .get_next_line_length_exit_ok:
        dec r10
        mov rax, r10
        ret

    .get_next_line_length_exit_error:
        mov rax, -1
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
