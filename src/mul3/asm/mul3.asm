DEFAULT REL		; Define relative addresses

; Import the required external symbols
extern _read
extern _write
extern _exit

; Export entry point
global _start

SECTION .data
    ; Define carriage return and line feed
    CRLF        db  10, 0      ; Line feed and null terminator
    CRLF_LEN    equ $ - CRLF   ; Length of CRLF (1 byte)

SECTION .bss
    ; Reserve space for buffers
    alignb 8
    INPUT_BUFFER    resb 128    ; Buffer for user input
    OUTPUT_BUFFER   resb 128    ; Buffer for output

SECTION .text

_start:
    ; Step 1: Read Input
    mov rdi, INPUT_BUFFER      ; Address of input buffer
    mov rsi, 128               ; Maximum bytes to read
    call _read                 ; Read from stdin
    mov rbx, rax               ; Save the number of bytes read

    ; Step 2: Convert String to Integer
    mov rdi, INPUT_BUFFER      ; Address of input buffer
    call string_to_int         ; Convert input string to integer
    ; Result is in RAX

    ; Step 3: Multiply by 3
    imul rax, rax, 3           ; Multiply RAX by 3

    ; Step 4: Convert Integer to String
    mov rdi, OUTPUT_BUFFER     ; Address of output buffer
    call int_to_string         ; Convert integer to string
    ; RAX contains the length of the output string

    ; Step 5: Write Output
    mov rdi, OUTPUT_BUFFER     ; Address of output buffer
    mov rsi, rax               ; Length of the output string
    call _write                ; Write to stdout

    ; Write a newline
    mov rdi, CRLF              ; Address of CRLF
    mov rsi, CRLF_LEN          ; Length of CRLF
    call _write                ; Write newline to stdout

    ; Step 6: Exit
    mov rdi, 0                 ; Exit code 0
    call _exit                 ; Terminate the program


string_to_int:
    xor rax, rax               ; Clear RAX (result)
    xor rcx, rcx               ; Index register

convert_loop:
    mov bl, [rdi + rcx]        ; Get character from input buffer
    cmp bl, 10                 ; Check for newline (ASCII 10)
    je convert_done            ; If newline, end conversion
    cmp bl, '0'                ; Check if character is '0' or higher
    jb invalid_input           ; If less, invalid input
    cmp bl, '9'                ; Check if character is '9' or lower
    ja invalid_input           ; If greater, invalid input

    sub bl, '0'                ; Convert ASCII to digit
    imul rax, rax, 10          ; Multiply current result by 10
    add rax, rbx               ; Add digit to result

    inc rcx                    ; Move to next character
    jmp convert_loop           ; Repeat loop

convert_done:
    ret

invalid_input:
    ; Handle invalid input by setting RAX to 0
    xor rax, rax
    ret

int_to_string:
    mov rcx, 0                 ; Digit count
    mov rbx, rax               ; Copy the integer to RBX

    cmp rax, 0
    jne int_to_string_loop
    ; Handle zero separately
    mov byte [rdi], '0'
    mov rax, 1                 ; Length of the string
    ret

int_to_string_loop:
    xor rdx, rdx               ; Clear RDX for division
    div qword [ten]            ; Divide RAX by 10
    add rdx, '0'               ; Convert remainder to ASCII
    push rdx                   ; Push digit onto stack
    inc rcx                    ; Increment digit count
    cmp rax, 0                 ; Check if quotient is zero
    jne int_to_string_loop     ; Continue if not zero

    ; Pop digits from stack to output buffer
    mov rsi, rcx               ; Length of the string
    mov rax, rcx               ; Return length in RAX

output_digits:
    pop rdx                    ; Get digit from stack
    mov [rdi], dl              ; Write digit to output buffer
    inc rdi                    ; Move to next position
    loop output_digits         ; Repeat for all digits

    ret

SECTION .data
ten     dq 10                  ; Constant value 10
