DEFAULT REL		; Define relative addresses

; Import the required external symbols
extern _read
extern _write
extern _exit

; Export entry point
global _start

SECTION .data
    ; Define carriage return and line feed
    CRLF        db  10, 0          ; Line feed and null terminator
    CRLF_LEN    equ $ - CRLF       ; Length of CRLF (1 byte)

    ten         dq 10              ; Constant value 10

SECTION .bss
    ; Reserve space for buffers
    alignb 8
    INPUT_BUFFER    resb 128       ; Buffer for user input
    OUTPUT_BUFFER   resb 128       ; Buffer for output

SECTION .text

_start:
    ; Step 1: Read Input
    mov rdi, INPUT_BUFFER          ; Address of input buffer
    mov rsi, 128                   ; Maximum bytes to read
    call _read                     ; Read from stdin
    mov rbx, rax                   ; Save the number of bytes read

    ; Step 2: Convert String to Integer
    mov rdi, INPUT_BUFFER          ; Address of input buffer
    call string_to_int             ; Convert input string to integer
    ; Result is in RAX

    ; Step 3: Multiply by 3
    imul rax, rax, 3               ; Multiply RAX by 3

    ; Step 4: Convert Integer to String
    mov rdi, OUTPUT_BUFFER         ; Address of output buffer
    call int_to_string             ; Convert integer to string
    ; RAX contains the length of the output string

    ; Step 5: Write Output
    mov rdi, OUTPUT_BUFFER         ; Address of output buffer
    mov rsi, rax                   ; Length of the output string
    call _write                    ; Write to stdout

    ; Write a newline
    mov rdi, CRLF                  ; Address of CRLF
    mov rsi, CRLF_LEN              ; Length of CRLF
    call _write                    ; Write newline to stdout

    ; Step 6: Exit
    mov rdi, 0                     ; Exit code 0
    call _exit                     ; Terminate the program

string_to_int:
    xor rax, rax                   ; Clear RAX (result)
    xor rcx, rcx                   ; Index register
    xor rsi, rsi                   ; Sign flag (0 = positive, 1 = negative)

    ; Check for leading '+' or '-'
    mov bl, [rdi + rcx]            ; Get first character
    cmp bl, '-'
    je negative_number
    cmp bl, '+'
    je positive_number

    ; If no sign, continue parsing digits
parse_digits:
    ; Check for newline or null terminator
    cmp bl, 10                     ; Newline
    je convert_done
    cmp bl, 0                      ; Null terminator
    je convert_done

    ; Check if character is a digit
    cmp bl, '0'
    jb invalid_input
    cmp bl, '9'
    ja invalid_input

    ; Convert ASCII digit to integer
    sub bl, '0'                    ; Convert ASCII to digit (0-9)
    imul rax, rax, 10              ; Multiply current result by 10
    add rax, rbx                   ; Add digit to result

    ; Move to next character
    inc rcx
    mov bl, [rdi + rcx]
    jmp parse_digits

negative_number:
    mov rsi, 1                     ; Set sign flag to negative
    inc rcx                        ; Move to next character
    mov bl, [rdi + rcx]
    jmp parse_digits

positive_number:
    ; Sign flag is already zero (positive)
    inc rcx                        ; Move to next character
    mov bl, [rdi + rcx]
    jmp parse_digits

convert_done:
    cmp rsi, 1                     ; Check if number is negative
    jne string_to_int_done
    neg rax                        ; Negate RAX to make it negative
string_to_int_done:
    ret

invalid_input:
    ; Handle invalid input by setting RAX to 0
    xor rax, rax
    ret

int_to_string:
    push rbp                       ; Preserve base pointer
    mov rbp, rsp                   ; Set stack frame
    sub rsp, 16                    ; Allocate space on stack

    xor rcx, rcx                   ; Digit count
    mov rbx, rax                   ; Copy the integer to RBX

    ; Check for zero
    cmp rax, 0
    jne int_to_string_process

    ; Handle zero separately
    mov byte [rdi], '0'
    mov rax, 1                     ; Length of the string
    jmp int_to_string_done

int_to_string_process:
    ; Check if number is negative
    mov rsi, 0                     ; Sign flag (0 = positive, 1 = negative)
    cmp rax, 0
    jge int_to_string_loop         ; If number >= 0, continue
    mov rsi, 1                     ; Set sign flag to negative
    neg rax                        ; Make RAX positive

int_to_string_loop:
    xor rdx, rdx                   ; Clear RDX for division
    div qword [ten]                ; Divide RAX by 10
    add rdx, '0'                   ; Convert remainder to ASCII
    push rdx                       ; Push digit onto stack
    inc rcx                        ; Increment digit count
    cmp rax, 0                     ; Check if quotient is zero
    jne int_to_string_loop         ; Continue if not zero

    ; If negative, add '-' to output
    cmp rsi, 1
    jne output_digits
    mov byte [rdi], '-'            ; Add '-' sign
    inc rdi                        ; Move to next position
    inc rcx                        ; Increment digit count

output_digits:
    ; Pop digits from stack to output buffer
    mov rax, rcx                   ; Return length in RAX
output_digits_loop:
    pop rdx                        ; Get digit from stack
    mov [rdi], dl                  ; Write digit to output buffer
    inc rdi                        ; Move to next position
    loop output_digits_loop        ; Repeat for all digits

int_to_string_done:
    add rsp, 16                    ; Clean up stack
    pop rbp                        ; Restore base pointer
    ret

