/*
 * termios.s: Raw mode terminal functions using `stty`
 */

.equ FORK,     97
.equ EXECVE,   221
.equ WAITPID,  260
.equ EXIT,     93

.global enable_raw_mode
.global disable_raw_mode

.section .rodata
stty_path:      .asciz "/bin/stty"
stty_arg_raw:   .asciz "raw"
stty_arg_cooked:.asciz "-raw"
stty_arg_echo:  .asciz "-echo"

.text

// Helper to run /bin/stty with a given argument
// Arg X0: address of the argument string (e.g., "raw" or "-raw")
run_stty:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp

    // Save the argument for later
    mov     x19, x0

    // Build the argv array on the stack
    // argv[0] = "/bin/stty"
    // argv[1] = the argument (e.g. "raw")
    // argv[2] = NULL
    ldr     x1, =stty_path
    str     x1, [sp, #16]
    str     x19, [sp, #24]
    str     xzr, [sp, #32]          // Null terminator

    // Fork the process
    mov     x8, #FORK
    svc     #0
    // x0 now holds the PID. 0 for child, >0 for parent.
    cbz     x0, .L_child_process

.L_parent_process:
    // waitpid(pid, NULL, 0)
    // x0 already contains the PID from the fork
    mov     x1, xzr                 // status (not needed)
    mov     x2, xzr                 // options
    mov     x8, #WAITPID
    svc     #0
    b       .L_stty_done

.L_child_process:
    // execve("/bin/stty", argv, NULL)
    ldr     x0, =stty_path
    add     x1, sp, #16             // address of argv array
    mov     x2, xzr                 // envp = NULL
    mov     x8, #EXECVE
    svc     #0

    // If execve returns, it's an error. Exit child.
    mov     w0, #127                // Command not found
    mov     x8, #EXIT
    svc     #0

.L_stty_done:
    ldp     x29, x30, [sp], #48
    ret


enable_raw_mode:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    ldr     x0, =stty_arg_raw
    bl      run_stty
    ldr     x0, =stty_arg_echo      // Also disable echo explicitly
    bl      run_stty

    ldp     x29, x30, [sp], #16
    ret

disable_raw_mode:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    ldr     x0, =stty_arg_cooked
    bl      run_stty

    ldp     x29, x30, [sp], #16
    ret 
