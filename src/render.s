/*
 * render.s: Terminal rendering logic
 */
.include "definitions.s"

.equ STDOUT, 1
.equ WRITE, 64

.global render_init
.global render_snake
.global render_clear_tail

.section .rodata
clear_screen_seq: .byte 0x1b, '[', '2', 'J'
.equ clear_screen_len, . - clear_screen_seq
hide_cursor_seq:  .byte 0x1b, '[', '?', '2', '5', 'l'
.equ hide_cursor_len, . - hide_cursor_seq
snake_char:       .ascii "#"
clear_char:       .ascii " "

.text

// Small helper to write a buffer to STDOUT
// Args: x0=address, x1=length
write_stdout:
    stp     x29, x30, [sp, #-32]!
    stp     x19, x20, [sp, #16]
    mov     x29, sp

    // Securely copy arguments to prevent corruption from caller state
    mov     x19, x0                 // x19 = buffer address
    mov     x20, x1                 // x20 = length

    // Prepare for syscall using the saved, safe copies
    mov     x0, #STDOUT             // fd
    mov     x1, x19                 // buf
    mov     x2, x20                 // count
    mov     x8, #WRITE
    svc     #0

    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

render_init:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // Clear screen
    ldr     x0, =clear_screen_seq
    mov     x1, #clear_screen_len
    bl      write_stdout

    // Hide cursor
    ldr     x0, =hide_cursor_seq
    mov     x1, #hide_cursor_len
    bl      write_stdout

    ldp     x29, x30, [sp], #16
    ret

render_snake:
    // Allocate 80-byte stack frame for robust register saving
    stp     x29, x30, [sp, #-80]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]

    // Get snake properties
    ldr     x19, =snake_body      // x19 = base address of snake body
    ldr     x9, =snake_len
    ldr     w20, [x9]             // w20 = snake_len

    mov     x21, #0                 // Loop counter i=0

.L_loop_snake_body:
    cmp     x21, x20                // while(i < snake_len)
    b.ge    .L_loop_end

    // Read snake segment {Y, X}
    lsl     x22, x21, #1            // byte offset = i * 2
    add     x22, x19, x22           // Address of snake_body[i]
    ldrh    w11, [x22]              // Load {Y,X} pair as a halfword
    lsr     w24, w11, #8            // w24 = X
    uxtb    w23, w11                // w23 = Y

    // Build ANSI escape code in a safe buffer on the stack (sp + 64)
    add     x11, sp, #64
    mov     x10, x11

    mov     w9, #0x5b1b
    strh    w9, [x10], #2

    // --- Inlined utoa8 for Y coordinate (w23) ---
    mov     w0, w23
    mov     x2, #10
    udiv    w3, w0, w2
    msub    w4, w3, w2, w0
    add     w3, w3, #'0'
    add     w4, w4, #'0'
    cmp     w3, #'0'
    b.eq    .L_render_snake_1
    strb    w3, [x10], #1
.L_render_snake_1:
    strb    w4, [x10], #1

    mov     w9, #';'
    strb    w9, [x10], #1

    // --- Inlined utoa8 for X coordinate (w24) ---
    mov     w0, w24
    mov     x2, #10
    udiv    w3, w0, w2
    msub    w4, w3, w2, w0
    add     w3, w3, #'0'
    add     w4, w4, #'0'
    cmp     w3, #'0'
    b.eq    .L_render_snake_2
    strb    w3, [x10], #1
.L_render_snake_2:
    strb    w4, [x10], #1

    mov     w9, #'H'
    strb    w9, [x10], #1

    mov     x0, x11
    sub     x1, x10, x11
    bl      write_stdout

    ldr     x0, =snake_char
    mov     x1, #1
    bl      write_stdout

    add     x21, x21, #1
    b       .L_loop_snake_body

.L_loop_end:
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #80
    ret

render_clear_tail:
    // Args: w0=Y, w1=X
    // Allocate 48-byte stack frame: 16 for FP/LR, 16 for x19/x20, 16 for buffer
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]     // Save temp registers

    // Preserve args
    mov     w19, w0
    mov     w20, w1

    // Build ANSI escape code in a safe buffer on the stack
    add     x11, sp, #32            // Buffer starts at sp + 32, a safe area
    mov     x10, x11

    mov     w9, #0x5b1b
    strh    w9, [x10], #2

    // --- Inlined utoa8 for Y coordinate (w19) ---
    mov     w0, w19
    mov     x2, #10
    udiv    w3, w0, w2
    msub    w4, w3, w2, w0
    add     w3, w3, #'0'
    add     w4, w4, #'0'
    cmp     w3, #'0'
    b.eq    .L_render_clear_1
    strb    w3, [x10], #1
.L_render_clear_1:
    strb    w4, [x10], #1
    // --- End inlined utoa8 ---

    mov     w9, #';'
    strb    w9, [x10], #1

    // --- Inlined utoa8 for X coordinate (w20) ---
    mov     w0, w20
    mov     x2, #10
    udiv    w3, w0, w2
    msub    w4, w3, w2, w0
    add     w3, w3, #'0'
    add     w4, w4, #'0'
    cmp     w3, #'0'
    b.eq    .L_render_clear_2
    strb    w3, [x10], #1
.L_render_clear_2:
    strb    w4, [x10], #1
    // --- End inlined utoa8 ---

    mov     w9, #'H'
    strb    w9, [x10], #1

    mov     x0, x11
    sub     x1, x10, x11
    bl      write_stdout

    // Write the clear character
    ldr     x0, =clear_char
    mov     x1, #1
    bl      write_stdout

    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
