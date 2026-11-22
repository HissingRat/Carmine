.section .text
.extern interrupt_dispatch

.macro ISR vector, error=0    ;# 没有error code, 手动push一个 0 作为error code, 然后push vector
.global isr\vector            ;# 有error code, cpu会先push error code, 那我们直接push vector
isr\vector:
    .if \error == 0
        pushq $0
    .endif
    pushq $\vector
    jmp isr_common
.endm

.global isr_common
isr_common:
    cld

    push %rax
    push %rbx
    push %rcx
    push %rdx
    push %rbp
    push %rdi
    push %rsi
    push %r8
    push %r9
    push %r10
    push %r11
    push %r12
    push %r13
    push %r14
    push %r15

    movq %rsp, %rdi          ;# 加载第一个参数: *InterruptFrame
    call interrupt_dispatch

    pop %r15
    pop %r14
    pop %r13
    pop %r12
    pop %r11
    pop %r10
    pop %r9
    pop %r8
    pop %rsi
    pop %rdi
    pop %rbp
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax

    ;# 删掉vector index和error code
    add $16, %rsp
    iretq

.global isr_table
.balign 8
isr_table:
    .irp vector,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
        .quad isr\vector
    .endr

;# https://wiki.osdev.org/Interrupt_Descriptor_Table#IDT_items
ISR 0        ;# Divide Error
ISR 1        ;# Debug
ISR 2        ;# NMI
ISR 3        ;# Breakpoint
ISR 4        ;# Overflow
ISR 5        ;# Bound Range Exceeded
ISR 6        ;# Invalid Opcode
ISR 7        ;# Device Not Available
ISR 8, 1     ;# Double Fault
ISR 9
ISR 10, 1
ISR 11, 1
ISR 12, 1
ISR 13, 1
ISR 14, 1    ;# Page Fault
ISR 15
ISR 16
ISR 17, 1
ISR 18
ISR 19
ISR 20
ISR 21, 1
ISR 22
ISR 23
ISR 24
ISR 25
ISR 26
ISR 27
ISR 28
ISR 29, 1
ISR 30, 1
ISR 31