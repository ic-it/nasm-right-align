; IO utils. 
; This file contains the functions to open, read, write and close files.

global open_file, read_file, write_file, close_file, seek_file, write_stdout

; System call numbers
CALL_OPEN equ 2
CALL_READ equ 0
CALL_WRITE equ 1
CALL_CLOSE equ 3
CALL_SEEK equ 8

; Seek flags
SEEK_SET equ 0
SEEK_CUR equ 1
SEEK_END equ 2

; File descriptors
STDOUT equ 1
STDIN equ 0


section .text
; ## Open file
; ### Input:
;   - rdi: filename
;   - rsi: flags
;   - rdx: mode
; ### Output:
;   - rax: file descriptor
open_file:
    mov rax, CALL_OPEN
    syscall
    ret

; ## Read file
; ### Input:
;   - rdi: file descriptor
;   - rsi: buffer
;   - rdx: buffer size
; ### Output:
;   - rax: number of bytes read
read_file:
    mov rax, CALL_READ
    syscall
    ret

; ## Write file
; ### Input:
;   - rdi: file descriptor
;   - rsi: buffer
;   - rdx: buffer size
; ### Output:
;   - rax: number of bytes written
write_file:
    mov rax, CALL_WRITE
    syscall
    ret

; ## Close file
; ### Input:
;   - rdi: file descriptor
; ### Output:
;   - rax: 0 if success, -1 if error
close_file:
    mov rax, CALL_CLOSE
    syscall
    ret

; ## Seek file
; ### Input:
;   - rdi: file descriptor
;   - rsi: offset (bytes)
;   - rdx: whence (SEEK_SET, SEEK_CUR, SEEK_END)
; ### Output:
;   - rax: new offset
seek_file:
    mov rax, CALL_SEEK
    syscall
    ret

; ## Write to stdout
; ### Input:
;   - rsi: buffer
;   - rdx: buffer size
; ### Output:
;   - rax: number of bytes written
write_stdout:
    mov rdi, STDOUT
    call write_file
    ret

