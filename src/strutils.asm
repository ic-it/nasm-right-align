; String Utils
; This File implements a few string manipulation functions

global strlen, strcmp, itoa


section .text
; Get String Length
; ## Input
; - rsi: Pointer to the string
; ## Output
; - rax: Length of the string
strlen:
    xor rax, rax ; Clear rax
    .strlen_loop:
        cmp byte [rsi + rax], 0 ; Check if the current character is \0
        je .strlen_done ; If it is, we are done
        inc rax ; Increment the length
        jmp .strlen_loop ; Repeat
    .strlen_done:
    ret


; Compare Strings
; ## Input
; - rsi: Pointer to the first string
; - rdi: Pointer to the second string
; ## Output
; - rax: 0 if the strings are equal, 1 if they are not
strcmp:
    .strcmp_loop:
        mov al, [rsi] ; Load the current character from the first string
        mov bl, [rdi] ; Load the current character from the second string
        cmp al, bl ; Compare the characters
        jne .strcmp_not_equal ; If they are not equal, return 1
        cmp al, 0 ; Check if we reached the end of the first string
        je .strcmp_done ; If we did, return 0
        inc rsi ; Move to the next character in the first string
        inc rdi ; Move to the next character in the second string
        jmp .strcmp_loop ; Repeat
    .strcmp_not_equal:
        mov rax, 1 ; The strings are not equal
        ret
    .strcmp_done:
        xor rax, rax ; The strings are equal
        ret

; Integer to Null-Terminated String
; ## Input
; - rdi: Integer to convert
; - rsi: Pointer to the buffer
; Output
; - rax: String length
; ---
; Push to stack the digits of the number
; Pop from stack and write to buffer
; add null terminator
itoa:
    push r8
    push r10
    push r11

    mov r8, rsp ; Stack pointer
    mov rax, rdi ; Copy the number to rax
    mov r10, rsi ; Copy the buffer pointer to r10

    xor r11, r11 ; Clear r11
    mov rcx, 10 ; Base 10

    .itoa_loop:
        xor rdx, rdx ; Clear rdx
        div rcx ; Divide rax by 10
        add dl, '0' ; Convert the remainder to ASCII
        push rdx ; Push the digit to the stack
        inc r11 ; Increment the length
        test rax, rax ; Check if we are done
        jnz .itoa_loop ; If not, repeat
    
    .itoa_write:
        pop rdx ; Pop the digit from the stack
        mov [r10], dl ; Write the digit to the buffer
        inc r10 ; Move to the next character
        cmp r8, rsp ; Check if we are done
        jne .itoa_write ; If not, repeat
    
    inc r11 ; Increment the length
    mov byte [r10], 0 ; Null-terminate the string
    mov rax, r11 ; Return the length

    bp_:
    pop r11
    pop r10
    pop r8
    ret