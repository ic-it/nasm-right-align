
; Clear register
; **Params:**
; - %1: register to clear
; **Example:**
;   clear_reg eax
%macro clear_reg 1
    xor %1, %1
%endmacro

; Using cmovg to avoid branching
; **Params:**
; - %1: register to store max value
; - %2: register to compare
; **Example:**
;   maxval = val > maxval ? val : maxval
%macro set_max 2
    cmp %2, %1
    cmovg %1, %2
%endmacro

; Using cmovl to avoid branching
; **Params:**
; - %1: register to store min value
; - %2: register to compare
; **Example:**
;   minval = val < minval ? val : minval
%macro set_min 2
    cmp %2, %1
    cmovl %1, %2
%endmacro

; Set zero if equal
; **Params:**
; - %1: register to set to 0 if equal
; - %2: register to compare
; - %3: register to compare
; **Example:**
;   val = (x == y) ? 0 : val;
%macro zero_if_equal 3
    push rax
    clear_reg rax
    cmp %2, %3
    cmove %1, rax
    pop rax
%endmacro