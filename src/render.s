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

// Writes a buffer to STDOUT.
// Args: x0=address, x1=length
// Clobbers: x0-x2, x8
write_stdout:
    mov     x8, #WRITE
    mov     x0, #STDOUT
    // x1 (buf) and x2 (len) are passed through
    svc     #0
    ret

// Converts an 8-bit unsigned integer to a 2-digit string.
// Suppresses leading zero.
// Args: w0 = integer, x1 = buffer address
// Returns: x0 = number of bytes written
// Clobbers: x0-x4
utoa8:
    mov     x2, #10
    udiv    w3, w0, w2          // w3 = val / 10 (tens digit)
    msub    w4, w3, w2, w0      // w4 = val - (tens * 10) (ones digit)
    add     w3, w3, #'0'
    add     w4, w4, #'0'

    mov     x0, #0              // Bytes written
    cmp     w3, #'0'
    b.eq    1f
    strb    w3, [x1], #1        // Store tens digit if not '0'
    add     x0, x0, #1
1:
    strb    w4, [x1], #1        // Store ones digit
    add     x0, x0, #1
    ret


// Renders one character at a given coordinate.
// Args: w0=Y, w1=X, x2=char_addr, x3=char_len
render_char_at:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16] // Save registers
    stp     x21, x22, [sp, #32]

    // Preserve args
    mov     w19, w0         // Y
    mov     w20, w1         // X
    mov     x21, x2         // char_addr
    mov     x22, x3         // char_len

    // Get a pointer to the on-stack buffer
    add     x10, sp, #32    // Use the top 16 bytes of our 48-byte frame
    mov     x11, x10        // Keep original buffer start in x11

    // Build ANSI escape code: "\x1b["
    mov     w9, #0x5b1b
    strh    w9, [x10], #2

    // Convert Y (w19) to string
    mov     w0, w19
    mov     x1, x10
    bl      utoa8
    add     x10, x10, x0 // Advance buffer pointer

    // ";"
    mov     w9, #';'
    strb    w9, [x10], #1

    // Convert X (w20) to string
    mov     w0, w20
    mov     x1, x10
    bl      utoa8
    add     x10, x10, x0 // Advance buffer pointer

    // "H"
    mov     w9, #'H'
    strb    w9, [x10], #1

    // Write the escape sequence
    mov     x1, x11
    sub     x2, x10, x11
    bl      write_stdout

    // Write the character itself
    mov     x1, x21
    mov     x2, x22
    bl      write_stdout

    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret


render_init:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    ldr     x1, =clear_screen_seq
    mov     x2, #clear_screen_len
    bl      write_stdout

    ldr     x1, =hide_cursor_seq
    mov     x2, #hide_cursor_len
    bl      write_stdout

    ldp     x29, x30, [sp], #16
    ret

render_snake:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]

    ldr     x19, =snake_body
    ldr     x9, =snake_len
    ldr     w20, [x9]

    mov     x21, #0
1:  // Loop start
    cmp     x21, x20
    b.ge    2f  // Loop end

    lsl     x22, x21, #1
    add     x22, x19, x22
    ldrh    w11, [x22]
    lsr     w1, w11, #8     // X
    uxtb    w0, w11         // Y

    ldr     x2, =snake_char
    mov     x3, #1
    bl      render_char_at

    add     x21, x21, #1
    b       1b
2:  // Loop end

    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

render_clear_tail:
    // Args: w0=Y, w1=X
    ldr     x2, =clear_char
    mov     x3, #1
    b       render_char_at // Tail call
