/*
 * snake.s: Game state and logic
 */
.include "definitions.s"

.global snake_body
.global snake_len
.global snake_dir
.global snake_advance

.data
.align 2
snake_body:
    // Snake body stored as [Y, X] pairs (1 byte each)
    .byte 10, 10  // Tail
    .byte 10, 11
    .byte 10, 12
    .byte 10, 13  // Head
    // Reserve space for the rest of the body
    .space (MAX_SNAKE_LEN - 4) * 2

snake_len:
    .word 4

snake_dir:
    // 0:right, 1:left, 2:up, 3:down
    .byte 0

// Branchless direction mapping: {dX, dY} pairs for {R, L, U, D}
direction_deltas:
    .byte 1, 0   // Right
    .byte -1, 0  // Left
    .byte 0, -1  // Up
    .byte 0, 1   // Down

.text
snake_advance:
    stp     x29, x30, [sp, #-32]!
    stp     x19, x20, [sp, #16]
    mov     x29, sp

    // Load state
    ldr     x19, =snake_body
    ldr     x9, =snake_len
    ldr     w20, [x9]           // w20 = snake_len

    // 1. Shift body array one element to the left
    // Equivalent to: for(i=0; i < snake_len-1; i++) body[i] = body[i+1]
    mov     x1, x19             // dest = &snake_body[0]
    add     x0, x19, #2         // src = &snake_body[1]
    sub     w2, w20, #1         // n_pairs = snake_len - 1
shift_loop:
    ldrh    w3, [x0], #2
    strh    w3, [x1], #2
    subs    w2, w2, #1
    b.ne    shift_loop

    // 2. Calculate new head position
    // Get old head (which is now at the second-to-last position)
    sub     w10, w20, #1
    add     x11, x19, w10, uxtw #1
    ldrh    w11, [x11]          // w11 = {Y, X} of old head
    lsr     w13, w11, #8        // w13 = X
    uxtb    w12, w11            // w12 = Y

    // Get dX, dY from lookup table
    ldr     x9, =snake_dir
    ldrb    w10, [x9]
    ldr     x14, =direction_deltas
    add     x14, x14, w10, uxtw #1
    ldrsb   w15, [x14, #1]      // dY (signed)
    ldrsb   w16, [x14, #0]      // dX (signed)

    // Calculate new head coordinates
    add     w12, w12, w15       // newY = Y + dY
    add     w13, w13, w16       // newX = X + dX

    // 3. Store new head at the end of the array
    add     x11, x19, w20, uxtw #1  // Use snake_len as the index for the new head
    lsl     w13, w13, #8
    orr     w12, w12, w13       // w12 = {newX, newY}
    strh    w12, [x11]

    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
