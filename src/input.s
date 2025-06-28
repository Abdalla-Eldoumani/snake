/*
 * input.s: Non-blocking keyboard input handling
 */
.include "definitions.s"

.equ FCNTL,        25
.equ READ,         63
.equ STDIN_FILENO, 0
.equ F_GETFL,      3
.equ F_SETFL,      4
.equ O_NONBLOCK,   2048

.global enable_nonblock_mode
.global disable_nonblock_mode
.global handle_input

.section .data
original_flags: .word 0

.text

enable_nonblock_mode:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // Get current flags: fcntl(STDIN_FILENO, F_GETFL, 0)
    mov     x0, #STDIN_FILENO
    mov     x1, #F_GETFL
    mov     x2, #0
    mov     x8, #FCNTL
    svc     #0
    // x0 now holds the current flags

    // Save original flags
    ldr     x1, =original_flags
    str     w0, [x1]

    // Set O_NONBLOCK
    orr     x0, x0, #O_NONBLOCK

    // Set new flags: fcntl(STDIN_FILENO, F_SETFL, new_flags)
    mov     x2, x0
    mov     x0, #STDIN_FILENO
    mov     x1, #F_SETFL
    mov     x8, #FCNTL
    svc     #0

    ldp     x29, x30, [sp], #16
    ret

disable_nonblock_mode:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // Load original flags
    ldr     x1, =original_flags
    ldr     w2, [x1]

    // Restore flags: fcntl(STDIN_FILENO, F_SETFL, original_flags)
    mov     x0, #STDIN_FILENO
    mov     x1, #F_SETFL
    mov     x8, #FCNTL
    svc     #0

    ldp     x29, x30, [sp], #16
    ret

// Reads a key and updates snake_dir if valid.
handle_input:
    // --- ISOLATION TEST ---
    // This function is temporarily disabled to isolate the rendering bug.
    // It will do nothing and return immediately.
    ret

/*
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]

    // Read 1 byte from stdin: read(STDIN_FILENO, &buffer, 1)
    sub     sp, sp, #16             // Make space for 1-byte buffer + alignment
    mov     x1, sp
    mov     x0, #STDIN_FILENO
    mov     x2, #1
    mov     x8, #READ
    svc     #0
    // x0 holds number of bytes read, or -1 (EAGAIN) if no data

    cmp     x0, #0
    b.le    .L_no_input             // If 0 or -1 bytes, no new input

    ldrb    w20, [sp]               // w20 = the character read

    // Get current direction
    ldr     x9, =snake_dir
    ldrb    w19, [x9]

    // Determine new direction from keypress
    // d: 0, a: 1, w: 2, s: 3
    mov     w10, #-1                // Default to invalid
    cmp     w20, #'d'
    csel    w10, wzr, w10, eq       // If 'd', new_dir = 0
    cmp     w20, #'a'
    mov     w11, #1
    csel    w10, w11, w10, eq       // If 'a', new_dir = 1
    cmp     w20, #'w'
    mov     w11, #2
    csel    w10, w11, w10, eq       // If 'w', new_dir = 2
    cmp     w20, #'s'
    mov     w11, #3
    csel    w10, w11, w10, eq       // If 's', new_dir = 3

    cmp     w10, #0
    b.lt    .L_no_input             // Invalid key

    // Prevent 180-degree turns. (current + 2) % 4 == new
    // The directions are now {d, a, w, s} -> {0, 1, 2, 3}
    // So right/left is 0/1 and up/down is 2/3.
    // A 180 turn is when (new_dir XOR 1) == current_dir
    eor     w11, w19, #1
    cmp     w11, w10
    b.eq    .L_no_input             // Is a 180 turn, ignore

    // Valid move, update direction
    strb    w10, [x9]

.L_no_input:
    add     sp, sp, #16             // Restore stack pointer
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret 
*/
