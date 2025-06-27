/*
 * main.s: Main application logic
 */
.global main

.text

main:
    // Initialize the renderer (clear screen, etc.)
    bl      render_init

    // Render the current game state
    bl      render_snake

    // For now, we just draw one frame and exit.
    // The game loop will go here.
    ret
