/*
 * main.s: Main application logic
 */
.equ CLOCK_MONOTONIC, 1
.equ NANOSLEEP, 101

.global main

.text

main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp

    bl      enable_raw_mode
    bl      enable_nonblock_mode

    // Setup timespec struct for 100ms delay
    mov     x1, #0              // tv_sec = 0
    ldr     x2, =100000000      // tv_nsec = 100,000,000
    stp     x1, x2, [sp, #16]   // Store timespec on the stack

    // Initialize the renderer
    bl      render_init

    // The program will now exit. The game loop is bypassed.
    // b       exit_program

game_loop:
    // Check for user input
    bl      handle_input

    // Store old tail position before advancing
    ldr     x9, =snake_body
    ldrh    w19, [x9]           // w19 = {Y, X} of old tail (Y in low byte)

    // Advance game state
    bl      snake_advance

    // Render the new frame
    bl      render_snake

    // Clear the old tail segment -- DISABLED FOR TEST
    // lsr     w20, w19, #8        // w20 = X
    // uxtb    w19, w19          // w19 = Y
    // mov     w0, w19
    // mov     w1, w20
    // bl      render_clear_tail

    // Sleep for a bit
    mov     x0, #CLOCK_MONOTONIC
    mov     x1, #0                  // flags
    add     x2, sp, #16             // address of timespec
    mov     x3, #0                  // remaining time (not used)
    mov     x8, #NANOSLEEP
    svc     #0

    b       game_loop

exit_program:
    bl      disable_nonblock_mode
    bl      disable_raw_mode
    // The loop is infinite, but for completeness:
    ldp     x29, x30, [sp], #32
    mov     w0, #0 // Return 0
    ret
