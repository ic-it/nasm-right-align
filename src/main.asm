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
extern open_file, read_file, write_file, close_file, seek_file, write_stdout, write_one_byte, write_newline

; From argsutils
extern init_args, get_argc, get_argv, get_arg

; From strutils
extern strlen, strcmp, itoa

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
    filename_msg db 'File: ', 0
    filename_msg_len equ $-filename_msg

    help_message db "This program reads a file and ligns it's content to the right", 0xa, 0
    help_message_len equ $-help_message

    author_msg db 'Author: Illia Chaban', 0xa, 0
    author_msg_len equ $-author_msg

    usage_msg db 'Usage: ./program <filename1> <filename2> ...', 0xa, 'Options:', 0xa, '  -h: Show help', 0xa, '  -p: Paginate', 0xa, 0
    usage_msg_len equ $-usage_msg

    error_msg db 'Error', 0xa, 0
    error_msg_len equ $-error_msg

    error_maybe_forgor_return db 'ERROR!! Maybe you forgot to return', 0xa, 0
    error_maybe_forgor_return_len equ $-error_maybe_forgor_return

    read_more_msg db 'Read more...', 0
    read_more_msg_len equ $-read_more_msg

    max_lines_before_pause equ 10

    ; Pagination
    flag_read_more_text db '-p', 0
    flag_read_more_text_len equ $-flag_read_more_text

    ; Help
    flag_help_text db '-h', 0
    flag_help_text_len equ $-flag_help_text

    zero db 0


section .bss
    buffer resb BUFFER_SIZE
    buffer_len equ $-buffer

    fd resq 1

    display_line_number resq 1
    arg_number resq 1

section .data
    flag_read_more db 0
    flag_help db 0

section .text

; Show Help
; **Input:**
;   None
; **Output:**
;   None
show_help_message:
    mov rsi, help_message
    mov rdx, help_message_len
    call write_stdout

    mov rsi, author_msg
    mov rdx, author_msg_len
    call write_stdout

    mov rsi, usage_msg
    mov rdx, usage_msg_len
    call write_stdout

    ret

; Start
; ---
; **Registers:**
;   - r10: arg number
;   - r11: arg val
_start:
    ; Read the arguments
    mov rdi, [rsp] 
    lea rsi, [rsp + 8] 
    call init_args 

    ; Check if there is only one file
    call get_argc
    mov r10, rax
    cmp r10, 1
    jl no_files_exit

    ; process arguments
    mov qword [arg_number], 1

    .process_files_loop:
        ; Check if all the files were processed
        cmp r10, qword [arg_number]
        jle .process_files_exit

        ; Get the file name
        mov rdi, [arg_number]
        call get_arg

        ; Increment the arg number
        inc qword [arg_number]

        mov r11, rax ; Save the file name

        ; Check if the file name is a flag
        ; Check -h flag
        mov rsi, r11
        mov rdi, flag_help_text
        call strcmp
        cmp rax, 0
        jne .flag_help_continue
            mov byte [flag_help], 1
            jmp .process_files_loop
        .flag_help_continue:
        ; Check -p flag
        mov rsi, r11
        mov rdi, flag_read_more_text
        call strcmp
        cmp rax, 0
        jne .flag_read_more_continue
            mov byte [flag_read_more], 1
            jmp .process_files_loop
        .flag_read_more_continue:

        ; Process the file
        mov rdi, r11
        call process_file

        ; Write a new line
        call write_newline

        jmp .process_files_loop
    
    .process_files_exit:

    cmp byte [flag_help], 1
    jne .skip_help
        call show_help_message
    .skip_help:

    ; Exit the program
    jmp ok_exit


; Process File
; **Input:**
;   - rdi: File name
; **Output:**
;   None
; ---
; **Registers:**
;   - rsi: Buffer
;   - rdx: Buffer length
;   - r9: Max line length
;   - r10: filename 
process_file:
    push r9
    push r10
    clear_reg r9
    clear_reg r10

    mov r10, rdi ; Save the file name

    ; Set the display line number
    mov rdi, 1
    mov [display_line_number], rdi

    ; Print the file name message
    mov rsi, filename_msg
    mov rdx, filename_msg_len
    call write_stdout
    
    ; Print the file name
    mov rsi, r10
    call strlen
    mov rdx, rax
    call write_stdout

    ; New line
    call write_newline

    ; Open the file
    mov rdi, r10
    mov rsi, O_RDONLY
    xor rdx, rdx
    call open_file
    mov qword [fd], rax

    ; Check if the file was opened
    cmp rax, 0
    jl error_exit

    ; Get the max line length
    call get_max_line_length
    mov r9, rax ; Save the max line length

    ; Seek 0
    mov rdi, [fd]
    mov rsi, 0
    mov rdx, SEEK_SET
    call seek_file

    ; Display the lines
    mov rsi, r9
    call display_lines

    ; Close the file
    call close_file

    pop r10
    pop r9
    ret


; Get Max Line Length
; **Input:**
;   None
; **Output:**
;   - rax: Max line length
; ---
; **Registers:**
;   - rax: read bytes/return value
;   - rsi: Buffer
;   - rdx: Buffer length
;   - r9: Max line length
;   - r10: Line length
;   - r11: Current character
get_max_line_length:
    clear_reg r9 
    clear_reg r10
    clear_reg r11

    .read_file_loop:
        ; Read the file
        mov rdi, [fd]
        mov rsi, buffer
        mov rdx, BUFFER_SIZE
        call read_file

        ; Check if the file was read
        cmp rax, 0
        jle .get_max_line_length_exit

        ; Loop through the buffer
        mov rsi, buffer
        .loop_through_buffer:
            ; Check if the buffer is empty
            cmp rax, 0
            je .read_file_loop

            ; Get the character
            mov r11, rsi
            inc rsi
            dec rax

            set_max r9, r10

            inc r10 ; length = length + 1;

            zero_if_equal r10, byte [r11], 0xa
            
            ; Loop through the buffer
            jmp .loop_through_buffer

        ; Loop through the file
        jmp .read_file_loop
    
    .get_max_line_length_exit:
    set_max r9, r10

    mov rax, r9
    ret


; Display Lines
; **Input:**
;   - rsi: max line length
; **Output:**
;   None
; ---
; **Registers:**
;   - rax: read bytes
;   - r8: Max line length
;   - r9: Line length
;   - r10: White spaces length
;   - r11: TMP
display_lines:
    clear_reg r8
    clear_reg r9
    clear_reg r10
    clear_reg r11

    mov r8, rsi ; Save the max line length

    .display_loop:

        ; Get the length of the next line
        call get_next_line_length

        ; Check if the length is -1
        cmp rax, -1
        je .display_numbers_exit

        push rax
        ; Print the line number
        mov rdi, [display_line_number]
        mov rsi, buffer
        call itoa
        mov rdx, rax
        call write_stdout

        ; write tab
        mov dil, 9
        call write_one_byte

        ; Increment the line number
        inc qword [display_line_number]

        ; Display '|'
        mov dil, '|'
        call write_one_byte
        pop rax

        mov r9, rax ; Save the line length

        ; Repeat ' ' max_length - length times
        mov r10, r8
        sub r10, r9

        ; Fill buffer with white spaces
        call fill_buffer_with_white_spaces

        ; Display the white spaces
        .display_white_spaces:
            ; Check if there are white spaces to display
            cmp r10, 0
            jle .display_numbers_write_line

            ; Get the display size
            mov rax, r10
            mov r11, BUFFER_SIZE
            set_min rax, r11

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
            mov rsi, r9
            call display_line

            ; Display '|'
            mov dil, '|'
            call write_one_byte
            call write_newline

        ; Repeat
        jmp .display_loop
    
    .display_numbers_exit:
    ret


; Get the length of the next line in a file and seek back
; **Input:**
;   None
; **Output:**
;   - rax: length of the next line (line length + new line length)
; ---
; **Registers:**
;   - r8: Buffer length
;   - r9: Seekback
;   - r10: Length
;   - r11: Current character
;   - r12: TMP
get_next_line_length:
    push r8
    push r9
    push r10
    push r11
    push r12

    clear_reg r8
    clear_reg r9 
    clear_reg r10
    clear_reg r11
    clear_reg r12

    .read_file_loop:
        ; Read the file
        mov rdi, [fd]
        mov rsi, buffer
        mov rdx, BUFFER_SIZE
        call read_file

        ; Check if the file was read
        cmp rax, 0
        je .exit

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

            mov r12, 1

            ; Return the length
            jmp .exit

        ; Loop through the buffer
        jmp .loop_through_buffer

    .exit:
        ; seek back
        mov rdi, [fd]
        mov rsi, r9
        neg rsi
        mov rdx, SEEK_CUR 
        call seek_file

        cmp r10, 0
        je .error_exit
        jmp .normal_exit

    .normal_exit:
        ; Decrement the length if the last character is a new line
        cmp r12, 1
        jne .dont_decrement
        dec r10
        .dont_decrement:

        ; Return the length
        mov rax, r10
        jmp .pop_exit

    .error_exit:
        mov rax, -1
        jmp .pop_exit
    
    .pop_exit:
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        ret

; Display one line (withou new line)
; **Input:**
;   - rsi: line length
; **Output:**
;   None
; ---
; **Registers:**
;   - r8: Buffer length
;   - r9: Line length
;   - r10: tmp
display_line:
    push r8
    push r9
    push r10

    clear_reg r8
    clear_reg r9
    clear_reg r10

    mov r9, rsi ; Save the line length

    .dispaly_line_loop:
        ; Check if the line is empty
        cmp r9, 0
        je .display_line_exit

        mov rax, r9
        mov r10, BUFFER_SIZE
        set_min rax, r10

        ; Read the file
        mov rdi, [fd]
        mov rsi, buffer
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
        ; read the new line
        mov rdi, [fd]
        mov rsi, buffer
        mov rdx, 1
        call read_file

    pop r10
    pop r9
    pop r8
    ret



; FIll Buffer with white spaces
; **Input:**
;   None
; **Output:**
;   None
; ---
; **Registers:**
;   - rdi: Buffer
;   - rcx: Buffer length
;   - rax: Character
fill_buffer_with_white_spaces:
    push rdi
    push rcx
    push rax

    mov rdi, buffer
    mov ecx, BUFFER_SIZE
    mov al, ' '
    rep stosb

    bp_:

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
