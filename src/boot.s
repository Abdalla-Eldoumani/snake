/*
 * boot.s: Process entry and exit
 */
.global _start      // Provide program starting address to linker

.text               // Code section

_start:
    // Enter raw terminal mode
    bl      enable_raw_mode

    // Call the main application logic
    bl      main

    // Restore terminal before exiting
    bl      disable_nonblock_mode
    bl      disable_raw_mode

    // Exit the program
    mov     x0, #0      // Exit code 0 (success)
    mov     x8, #93     // Service command code 93 is exit
    svc     #0          // Supervisor call to execute the exit

.end 
