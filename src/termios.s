/*
 * termios.s: Raw mode terminal functions
 */
.equ STDIN, 0
.equ IOCTL, 29

.equ TCGETS, 0x5401
.equ TCSETS, 0x5402

// c_lflag bits
.equ ECHO,   0x00000010
.equ ICANON, 0x00000002

.global enable_raw_mode
.global disable_raw_mode

.data
.align 8
original_termios: .space 60  // Reserve 60 bytes for the termios struct

.text

enable_raw_mode:
    stp     x29, x30, [sp, #-80]!   // Save FP, LR and allocate 80 bytes (60 for struct + 20 for alignment/padding)
    mov     x29, sp

    // Local termios struct is at [sp, #16]
    add     x10, sp, #16            // x10 holds address of local_termios

    // 1. Get current terminal settings
    // ioctl(STDIN, TCGETS, &original_termios)
    mov     x0, #STDIN
    mov     x1, #TCGETS
    ldr     x2, =original_termios
    mov     x8, #IOCTL
    svc     #0

    // 2. Copy original to local and modify for raw mode
    ldr     x2, =original_termios
    mov     x3, x10
    // A 60-byte copy can be done more efficiently with LDP/STP
    ldp     x4, x5, [x2, #0]
    ldp     x6, x7, [x2, #16]
    ldp     x8, x9, [x2, #32]
    ldp     x0, x1, [x2, #48] // loads 4 bytes extra, but ok
    stp     x4, x5, [x3, #0]
    stp     x6, x7, [x3, #16]
    stp     x8, x9, [x3, #32]
    stp     x0, x1, [x3, #48]

    // Clear ICANON and ECHO flags in c_lflag
    // c_lflag is at offset 12 in the termios struct for aarch64
    ldr     w6, [x10, #12]
    bic     w6, w6, #ICANON
    bic     w6, w6, #ECHO
    str     w6, [x10, #12]

    // 3. Set new terminal settings
    // ioctl(STDIN, TCSETS, &local_termios)
    mov     x0, #STDIN
    mov     x1, #TCSETS
    mov     x2, x10
    mov     x8, #IOCTL
    svc     #0

    ldp     x29, x30, [sp], #80     // Restore FP, LR and deallocate stack
    ret

disable_raw_mode:
    stp     x29, x30, [sp, #-16]!   // Save FP and LR

    // Restore original terminal settings
    // ioctl(STDIN, TCSETS, &original_termios)
    mov     x0, #STDIN
    mov     x1, #TCSETS
    ldr     x2, =original_termios
    mov     x8, #IOCTL
    svc     #0

    ldp     x29, x30, [sp], #16     // Restore FP and LR
    ret 
