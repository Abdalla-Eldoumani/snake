/*
 * snake.s: Game state and logic
 */
.include "definitions.s"

.global snake_body
.global snake_len
.global snake_dir
.global snake_advance
.global render_snake
.global render_clear_tail

.section .data
snake_body:
    .hword 0x0a0a, 0x0b0a, 0x0c0a, 0x0d0a // {Y,X} pairs. Head is at the end.
.equ snake_body_end, .
snake_len:  .word 4
snake_dir:  .byte 0                       // 0:d, 1:a, 2:w, 3:s

.section .text

// Branchless direction mapping: {dX, dY} pairs for {R, L, U, D}
direction_deltas:
    .byte 1, 0   // Right
    .byte -1, 0  // Left
    .byte 0, -1  // Up
    .byte 0, 1   // Down

snake_advance:
    stp     x29, x30, [sp, #-32]!
    stp     x19, x20, [sp, #16]
    mov     x29, sp

    // Load state
    ldr     x19, =snake_body
    ldr     x9, =snake_len
    ldr     w20, [x9]           // w20 = snake_len

    // 1. Shift body array one element to the left
    // This moves (snake_len - 1) halfwords from body[1] to body[0].
    mov     x1, x19             // dest = &snake_body[0]
    add     x0, x19, #2         // src  = &snake_body[1]
    sub     w2, w20, #1         // w2 = count = snake_len - 1
    cbz     w2, .L_calc_new_head // Nothing to shift if length is 1

.L_shift_loop:
    ldrh    w3, [x0], #2
    strh    w3, [x1], #2
    subs    w2, w2, #1
    b.ne    .L_shift_loop

.L_calc_new_head:
    // 2. Calculate new head position
    // Get old head, which is now at index (snake_len - 1) after the shift
    sub     x10, x20, #1        // x10 = old head index (64-bit)
    add     x11, x19, x10, lsl #1 // address of old head = base + index*2
    ldrh    w11, [x11]          // w11 = {X, Y} of old head
    lsr     w13, w11, #8        // w13 = X
    uxtb    w12, w11            // w12 = Y

    // Get dX, dY from lookup table based on snake_dir
    ldr     x9, =snake_dir
    ldrb    w10, [x9]           // w10 = current direction
    lsl     x10, x10, #1        // offset = direction * 2 (since deltas are 2 bytes)
    ldr     x14, =direction_deltas
    add     x14, x14, x10
    ldrsb   w16, [x14, #0]      // dX (signed)
    ldrsb   w15, [x14, #1]      // dY (signed)

    // Calculate new head coordinates
    add     w12, w12, w15       // newY = Y + dY
    add     w13, w13, w16       // newX = X + dX

    // 3. Store new head at the end of the array (index snake_len - 1)
    sub     x10, x20, #1        // index = snake_len - 1 (64-bit)
    add     x11, x19, x10, lsl #1 // address of new head = base + index*2
    lsl     w13, w13, #8        // Pack X into high byte
    orr     w12, w12, w13       // w12 = {X, Y}
    strh    w12, [x11]          // Store new head

    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
