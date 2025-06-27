/*
 * render.s: Terminal rendering logic
 */
.equ STDOUT, 1
.equ WRITE, 64

.global render_init
.global render_snake

.section .rodata
clear_screen_seq: .byte 0x1b, '[', '2', 'J'
.equ clear_screen_len, . - clear_screen_seq
hide_cursor_seq:  .byte 0x1b, '[', '?', '2', '5', 'l'
.equ hide_cursor_len, . - hide_cursor_seq
snake_char:       .ascii "#"

.text

// Small helper to write a buffer to STDOUT
// Args: x0=address, x1=length
write_stdout:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    // syscall write(STDOUT, buf, len)
    mov     x2, x1
    mov     x1, x0
    mov     x0, #STDOUT
    mov     x8, #WRITE
    svc     #0
    ldp     x29, x30, [sp], #16
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

// Converts an 8-bit unsigned integer in w0 to a string at the address in x1.
// Returns the number of digits in w0.
// Clobbers: x0-x5
utoa8:
    mov     x5, x1          // Save original buffer pointer
    mov     x2, #10         // Divisor
    udiv    w3, w0, w2      // w3 = w0 / 10 (tens digit)
    msub    w4, w3, w2, w0  // w4 = w0 - (w3 * 10) (ones digit)
    add     w3, w3, #'0'    // Convert to ASCII
    add     w4, w4, #'0'    // Convert to ASCII

    cmp     w3, #'0'
    b.eq    1f              // If tens digit is 0, skip storing it
    strb    w3, [x1], #1    // Store tens digit
1:
    strb    w4, [x1], #1    // Store ones digit
    sub     x0, x1, x5      // Return number of bytes written (new_ptr - old_ptr)
    ret

render_snake:
    stp     x29, x30, [sp, #-32]!   // Allocate 32 bytes for buffer and frame
    stp     x19, x20, [sp, #16]     // Save callee-saved registers
    mov     x29, sp

    // Get snake properties
    ldr     x19, =snake_body      // x19 = base address of snake body
    ldr     x9, =snake_len
    ldr     w20, [x9]             // w20 = snake_len
    ldr     x9, =snake_head_idx
    ldr     w9, [x9]              // w9 = head_idx

    // Calculate tail index: tail_idx = (head_idx - snake_len + 1)
    sub     w11, w9, w20
    add     w11, w11, #1
    // Python's % is a pain. Handle negative results.
    // tail_idx = (tail_idx + MAX_SNAKE_LEN) % MAX_SNAKE_LEN
    add     w11, w11, #MAX_SNAKE_LEN
    mov     w12, #MAX_SNAKE_LEN
    udiv    w13, w11, w12
    msub    w11, w13, w12, w11 // w11 = tail_idx

    mov     x21, #0                 // Loop counter i=0

loop_snake_body:
    cmp     x21, x20                // while(i < snake_len)
    b.ge    loop_end

    // Calculate current segment's index in the circular buffer
    add     w12, w11, w21           // w12 = tail_idx + i
    mov     w13, #MAX_SNAKE_LEN
    udiv    w14, w12, w13
    msub    w12, w14, w13, w12      // w12 = current_segment_idx

    // Read snake segment {Y, X}
    add     x22, x19, x12, lsl #1   // Address of snake_body[current_segment_idx]
    ldrb    w23, [x22, #0]          // Y coordinate
    ldrb    w24, [x22, #1]          // X coordinate

    // Build ANSI escape code in a safe buffer on the stack: \\x1b[<Y>;<X>H
    add     x11, sp, #16            // x11 = start of our safe buffer
    mov     x10, x11                // x10 = current position in buffer

    // Write "\\x1b[" (2 bytes)
    mov     w9, #0x5b1b             // ASCII for '[' is 0x5b, ESC is 0x1b
    strh    w9, [x10], #2           // Store halfword and advance pointer by 2

    // <Y>
    mov     w0, w23
    mov     x1, x10
    bl      utoa8
    add     x10, x10, x0

    // ";"
    mov     w9, #';'
    strb    w9, [x10], #1

    // <X>
    mov     w0, w24
    mov     x1, x10
    bl      utoa8
    add     x10, x10, x0

    // "H"
    mov     w9, #'H'
    strb    w9, [x10], #1

    // Write the escape code
    mov     x0, x11                 // Arg 1: start of the buffer
    sub     x1, x10, x11            // Arg 2: length (current_ptr - start_ptr)
    bl      write_stdout

    // Write the snake character
    ldr     x0, =snake_char
    mov     x1, #1
    bl      write_stdout

    add     x21, x21, #1            // i++
    b       loop_snake_body

loop_end:
    ldp     x19, x20, [sp, #16]     // Restore callee-saved registers
    ldp     x29, x30, [sp], #32
    ret
