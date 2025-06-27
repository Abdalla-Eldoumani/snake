/*
 * render.s: Terminal rendering logic
 */
.equ STDOUT, 1
.equ WRITE, 64

.global render_init
.global render_snake

.section .rodata
.align 1
clear_screen_seq: .ascii "\\x1b[2J"
hide_cursor_seq:  .ascii "\\x1b[?25l"
move_cursor_seq:  .ascii "\\x1b[" // Y;XH
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
    mov     x1, #4
    bl      write_stdout

    // Hide cursor
    ldr     x0, =hide_cursor_seq
    mov     x1, #6
    bl      write_stdout

    ldp     x29, x30, [sp], #16
    ret

// Converts an 8-bit unsigned integer in w0 to a string at the address in x1.
// Returns the number of digits in w0.
// Clobbers: x0-x4
utoa8:
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
    sub     w0, w1, w0      // Return number of digits written
    ret

render_snake:
    stp     x29, x30, [sp, #-32]!   // Allocate 32 bytes for buffer and frame
    mov     x29, sp

    // Get snake properties
    ldr     x19, =snake_body
    ldr     x20_addr, =snake_len
    ldr     w20, [x20_addr]
    mov     x21, #0                 // Loop counter i=0

loop_snake_body:
    cmp     x21, x20                // while(i < snake_len)
    b.ge    loop_end

    // Read snake segment {Y, X}
    add     x22, x19, x21, lsl #1   // Address of snake_body[i]
    ldrb    w23, [x22, #0]          // Y coordinate
    ldrb    w24, [x22, #1]          // X coordinate

    // Build ANSI escape code on the stack: \\x1b[<Y>;<X>H
    sub     sp, sp, #16             // Temp buffer for escape code
    mov     x10, sp                 // x10 is our buffer pointer

    // "\\x1b["
    ldr     x0, =move_cursor_seq
    ldr     w1, [x0]
    str     w1, [x10]
    add     x10, x10, #3            // Advance buffer pointer

    // <Y>
    mov     w0, w23
    mov     x1, x10
    bl      utoa8
    add     x10, x10, x0

    // ";"
    mov     w1, #';'
    strb    w1, [x10], #1

    // <X>
    mov     w0, w24
    mov     x1, x10
    bl      utoa8
    add     x10, x10, x0

    // "H"
    mov     w1, #'H'
    strb    w1, [x10], #1

    // Write the escape code
    mov     x0, sp
    sub     x1, x10, sp
    bl      write_stdout

    // Write the snake character
    ldr     x0, =snake_char
    mov     x1, #1
    bl      write_stdout

    add     sp, sp, #16             // Deallocate buffer
    add     x21, x21, #1            // i++
    b       loop_snake_body

loop_end:
    ldp     x29, x30, [sp], #32
    ret
