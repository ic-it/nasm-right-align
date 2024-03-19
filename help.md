# Read Args

```asm
sys_write  equ 1  ; the linux WRITE syscall
sys_exit   equ 60 ; the linux EXIT syscall
sys_stdout equ 1  ; the file descriptor for standard output (to print/write to)

length     equ 5  ; the length of the string we wish to print (fixed string length of the arguments)

section .data
    linebreak db 0x0A ; ASCII character 10, a line break

section .text
global  _start
_start:
    pop r8  ; pop the number of arguments from the stack
    pop rsi ; discard the program name, since we only want the commandline arguments

top:
                    ; loop condition
    cmp r8, 0 ; check if we have to print more arguments
    jz  exit  ; if not, jump to the 'end' label

                    ; print the argument
    mov     rax, sys_write  ; set the rax register to the syscall number we want to execute (WRITE)
    mov     rdi, sys_stdout ; specify the file we want to write to (standard output in this case)
    pop     rsi             ; pop a pointer to the string we want to print from the stack
    mov     rdx, length     ; specify the (fixed) length of the string we want to print
    syscall                 ; execute the system call

                    ; print a newline
    mov rax, sys_write  ; rax is overwritten by the kernel with the syscall return code, so we set it again
    mov rdi, sys_stdout
    mov rsi, linebreak  ; this time we want to print a line break
    mov rdx, 1          ; which is one byte long
    syscall
    
    dec r8  ; count down every time we print an argument until there are none left
    jmp top ; jump back to the top of the loop

                    ; the program is finished, now exit cleanly by calling the EXIT syscall
exit:
    mov     rax, sys_exit ; load the EXIT syscall number into rax
    mov     rdi, 0        ; the program return code
    syscall               ; execute the system call

```


# Read File
```asm
; declare exported symbols
global _start ; must be declared for linker (ld)


BUFF_SIZE equ 100

section .data
    buffer   db BUFF_SIZE dup(0) ; buffer to read into
    filename db 'test.txt', 0    ; file to read
    fd       dq 0                ; file descriptor

section .text

_start:
    ; Open the file
    mov rdi,  filename
    mov rsi,  0        ; O_RDONLY mode
    mov rax,  2        ; sys_open syscall number
    syscall
    mov [fd], rax      ; save file descriptor

read_loop:
    ; Read from file
    mov rdi, [fd]   ; file descriptor
    mov rsi, buffer ; buffer address
    mov rdx, 100    ; buffer size
    mov rax, 0      ; sys_read syscall number
    syscall

    ; Check if end of file
    cmp rax, 0
    je  close_file

    ; Print the read chunk
    mov rdi, 1      ; stdout file descriptor
    mov rsi, buffer ; buffer address
    mov rdx, rax    ; number of bytes read
    mov rax, 1      ; sys_write syscall number
    syscall

    jmp read_loop

close_file:
    ; Close the file
    mov rdi, [fd] ; file descriptor
    mov rax, 3    ; sys_close syscall number
    syscall

    ; Exit
    mov rax, 60  ; sys_exit syscall number
    xor rdi, rdi ; return 0 status
    syscall
```