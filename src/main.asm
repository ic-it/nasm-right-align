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
    call display_lines

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
; ## Input:
;   - rdi: file descriptor
;   - rsi: max line length
; ## Output:
;   None
display_lines:
    push rdi
    clear_reg r8; Max line length
    clear_reg r9; Line length
    clear_reg r10; White spaces length
    clear_reg r11; TMP

    mov r8, rsi ; Save the max line length

    .display_loop:
        ; Get the length of the next line
        pop rdi
        push rdi
        call get_next_line_length

        ; Check if the length is -1
        cmp rax, -1
        je .display_numbers_exit

        mov r9, rax ; Save the line length

        ; Repeat ' ' max_length - length times
        mov rax, r8 ; max_length
        sub rax, r9 ; max_length - length
        mov r10, rax ; Save the white spaces length

        ; Fill buffer with white spaces
        call fill_buffer_with_white_spaces

        ; Display the white spaces
        .display_white_spaces:
            ; Check if there are white spaces to display
            cmp r10, 0
            jle .display_numbers_write_line

            ; Get the display size
            mov rax, r10
            cmp rax, BUFFER_SIZE
            mov r10, BUFFER_SIZE
            cmovg rax, r10

            ; Write the white spaces
            mov rsi, buffer
            mov rdx, rax
            call write_stdout

            ; Update the white spaces length
            sub r10, rax

            ; Repeat
            jmp .display_white_spaces

        .display_numbers_write_line:
        ; Display the line
        mov rdi, rdi
        mov rsi, r9
        call display_line

        ; Repeat
        jmp .display_loop
    
    .display_numbers_exit:
    pop rdi
    ret


; Get the length of the next line in a file and seek back
; ## Input:
;   - rdi: file descriptor
; ## Output:
;   - rax: length of the next line (line length + new line length)
get_next_line_length:
    push r8
    push r9
    push r10
    push r11

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
        mov rax, r10
        jmp .get_next_line_length_normal_exit

    .get_next_line_length_exit_error:
        mov rax, -1
        jmp .get_next_line_length_normal_exit
    
    .get_next_line_length_normal_exit:
        pop r11
        pop r10
        pop r9
        pop r8
        ret

; Display one line (withou new line)
; ## Input:
;   - rdi: file descriptor
;   - rsi: line length
; ## Output:
;   None
display_line:
    push r8
    push r9
    push r10

    clear_reg r8 ; Buffer length
    clear_reg r9 ; Line length
    clear_reg r10 ; tmp

    mov r9, rsi ; Save the line length
    .dispaly_line_loop:
        ; get min of r9 and BUFFER_SIZE
        mov rax, r9
        cmp rax, BUFFER_SIZE
        mov r10, BUFFER_SIZE
        cmovg rax, r10

        ; Read the file
        mov rdi, rdi
        lea rsi, [buffer]
        mov rdx, rax
        call read_file

        ; Check if the file was read
        cmp rax, 0
        je .display_line_exit

        ; Write the line
        mov rsi, buffer
        mov rdx, rax
        call write_stdout
        
        ; Update the line length
        sub r9, rax

        ; Repeat
        jmp .dispaly_line_loop
    
    .display_line_exit:
    pop r10
    pop r9
    pop r8
    ret



; FIll Buffer with white spaces
; ## Input:
;   None
; ## Output:
;   None
fill_buffer_with_white_spaces:
    push rdi
    push rcx
    push rax

    ; mov rdi, buffer
    ; lea rdi, [buffer + BUFFER_SIZE - 1]
    ; mov rcx, BUFFER_SIZE
    ; mov al, ' '
    ; rep stosq

    mov rdi, buffer
    mov ecx, BUFFER_SIZE
    mov al, ' '
    rep stosb

    _bp:

    pop rax
    pop rcx
    pop rdi
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
