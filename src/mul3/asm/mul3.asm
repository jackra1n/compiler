DEFAULT REL        ; enables RIP-relative addressing

extern _read
extern _write
extern _exit

global _start      ; exports public label _start

    LENGTH EQU 128      ; definition constant LENGTH (buffer length)

section .bss
    alignb 8               ; align to 8 bytes for 64-bit system
    BUFFER resb LENGTH     ; buffer to hold input (128 bytes)

section .text

_start:
    ; Call _read to get input from stdin
    mov rdi, BUFFER             ; file descriptor (0 = stdin)
    mov rsi, LENGTH        ; address of BUFFER to store input
    call _read             ; call _read function (reads into BUFFER)

    ; Check if no input was read
    test rax, rax          ; check if rax (number of bytes read) is zero
    jz .exit               ; if no bytes were read, exit the program

    ; Process each character from BUFFER
    xor rbx, rbx           ; clear index register (rbx will be our index)
.loop_start:
    mov rdi, BUFFER        ; load the address of BUFFER
    add rdi, rbx           ; rdi points to the current character (BUFFER[rbx])
    movzx rax, byte [rdi]  ; move the current character into rax and zero-extend

    ; Check if we reached the end of the string (newline or null terminator)
    cmp rax, 10            ; check if we hit newline character (ASCII 10)
    je .end_loop           ; if yes, end the loop
    cmp rax, 0             ; check if it's a null terminator (ASCII 0)
    je .end_loop           ; if yes, end the loop

    ; Check if the character is a digit ('0' to '9')
    cmp rax, '0'
    jl .skip_char          ; if less than '0', skip (not a digit)
    cmp rax, '9'
    jg .skip_char          ; if greater than '9', skip (not a digit)

    ; Convert the ASCII character to integer and multiply by 3
    sub rax, '0'           ; convert ASCII to integer
    imul rax, 3       ; multiply the number by 3
    add rax, '0'           ; convert back to ASCII

    ; Store the result back in BUFFER at the same position
    mov [rdi], al          ; store the result

.skip_char:
    ; Move to the next character
    inc rbx                ; increment index
    jmp .loop_start        ; repeat the loop

.end_loop:
    ; Call _write to output the result to stdout
    mov rdi, BUFFER             ; file descriptor (1 = stdout)
    mov rsi, rbx        ; address of BUFFER with result
    call _write            ; call _write function (writes BUFFER content to stdout)

.exit:
    ; Call _exit to terminate the program
    mov rdi, 0             ; return code 0
    call _exit             ; call _exit to exit the program