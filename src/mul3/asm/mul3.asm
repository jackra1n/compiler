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
    mov rdi, BUFFER        ; address of BUFFER to store input
    mov rsi, LENGTH        ; number of bytes to read
    call _read             ; call _read function (reads into BUFFER)

    ; Convert the first ASCII character from BUFFER to integer and multiply by 3
    mov rdi, BUFFER        ; use address of BUFFER directly
    movzx rax, byte [rdi]  ; move the first byte from BUFFER and zero-extend it
    sub rax, '0'           ; convert ASCII to integer
    imul rax, rax, 3       ; multiply the number by 3
    add rax, '0'           ; convert back to ASCII

    ; Store the result back in BUFFER
    mov [rdi], al          ; store the result (single character)

    ; Call _write to output the result to stdout
    mov rdi, BUFFER        ; address of BUFFER with result
    mov rsi, rax           ; number of bytes to write (1 byte for result)
    call _write            ; call _write function (writes BUFFER content to stdout)

    ; Call _exit to terminate the program
    mov rdi, 0             ; return code 0
    call _exit             ; call _exit to exit the program