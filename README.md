

## Calling Convention
From: https://en.wikipedia.org/wiki/X86_calling_conventions

**Return value**: EAX
**Caller-saved registers**: EAX, ECX, EDX
**Callee-saved registers**: EBX, ESI, EDI, EBP, ESP


| Register  | Purpose                                       | Saved across calls |
|-----------|-----------------------------------------------|--------------------|
| %rax      | temp register; return value                   | No                 |
| %rbx      | callee-saved                                  | Yes                |
| %rsp      | stack pointer                                 | Yes                |
| %rbp      | callee-saved; base pointer                    | Yes                |
| %rdi      | used to pass 1st argument to functions        | No                 |
| %rsi      | used to pass 2nd argument to functions        | No                 |
| %rdx      | used to pass 3rd argument to functions        | No                 |
| %rcx      | used to pass 4th argument to functions        | No                 |
| %r8       | used to pass 5th argument to functions        | No                 |
| %r9       | used to pass 6th argument to functions        | No                 |
| %r10-r11  | temporary                                     | No                 |
| %r12-r15  | callee-saved registers                        | Yes                |
