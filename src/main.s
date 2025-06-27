/*
 * main.s: Main application logic
 */
.equ CLOCK_MONOTONIC, 1
.equ NANOSLEEP, 101

.global main

.text

main:
    // Setup timespec struct for 100ms delay
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    mov     x1, #0              // tv_sec = 0
    mov     x2, #100000000      // tv_nsec = 100,000,000
    stp     x1, x2, [sp, #16]   // Store timespec on the stack

    // Initialize the renderer
    bl      render_init

game_loop:
    // Advance game state
    bl      snake_advance

    // Render the current game state
    bl      render_snake

    // Sleep for a bit
    mov     x0, #CLOCK_MONOTONIC
    mov     x1, #0                  // flags
    add     x2, sp, #16             // address of timespec
    mov     x3, #0                  // remaining time (not used)
    mov     x8, #NANOSLEEP
    svc     #0

    b       game_loop

    // The loop is infinite, but for completeness:
    ldp     x29, x30, [sp], #32
    ret
