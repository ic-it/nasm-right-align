; String Utils
; This File implements a few string manipulation functions

global strlen, strcmp


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
