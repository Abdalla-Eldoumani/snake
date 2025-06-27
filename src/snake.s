/*
 * snake.s: Game state and logic
 */

.equ WORLD_WIDTH, 40
.equ WORLD_HEIGHT, 20
.equ MAX_SNAKE_LEN, 256

.global snake_body
.global snake_len
.global snake_dir

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
