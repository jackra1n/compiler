DEFAULT REL		; Define relative addresses

; Import the required external symbols
extern _read
extern _write
extern _exit

; Export entry point
global _start

SECTION .data
    ; Define constants
    CRLF        db  10                          ; Line feed
    CRLF_LEN    equ $ - CRLF                    ; Length of CRLF (1 byte)
    ten         dq 10                           ; Constant value 10

    ; Prompt message without null terminator
    PROMPT_MSG      db 'Please enter an integer value:', 10
    PROMPT_MSG_LEN  equ $ - PROMPT_MSG          ; Length of prompt message

    ; Result message without null terminator
    RESULT_MSG      db 'The result of value * 3 is: '
    RESULT_MSG_LEN  equ $ - RESULT_MSG          ; Length of result message

SECTION .bss
    ; Reserve space for buffers
    alignb 8
    INPUT_BUFFER    resb 128               ; Buffer for user input
    OUTPUT_BUFFER   resb 128               ; Buffer for output
    TEMP_BUFFER     resb 128               ; Temporary buffer for digits

SECTION .text

_start:
    ; Output prompt message before input
    mov rdi, PROMPT_MSG                    ; Address of prompt message
    mov rsi, PROMPT_MSG_LEN                ; Length of prompt message
    call _write                            ; Write prompt to stdout

    ; Step 1: Read Input
    mov rdi, INPUT_BUFFER                  ; Address of input buffer
    mov rsi, 128                           ; Maximum bytes to read
    call _read                             ; Read from stdin

    ; Optional: Null-terminate the input string
    mov rcx, rax                           ; rax contains the number of bytes read
    mov byte [INPUT_BUFFER + rcx], 0       ; Null-terminate the input

    ; Step 2: Convert String to Integer
    mov rdi, INPUT_BUFFER                  ; Address of input buffer
    call string_to_int                     ; Convert input string to integer
    ; Result is in RAX

    ; Step 3: Multiply by 3
    imul rax, rax, 3                       ; Multiply RAX by 3

    ; Save the result before calling _write
    push rax                               ; Save RAX (result) on the stack

    ; Output the result message
    mov rdi, RESULT_MSG                    ; Address of result message
    mov rsi, RESULT_MSG_LEN                ; Length of result message
    call _write                            ; Write result message to stdout

    ; Restore the result after _write
    pop rax                                ; Restore RAX (result)

    ; Step 4: Convert Integer to String
    mov rdi, OUTPUT_BUFFER                 ; Address of output buffer
    call int_to_string                     ; Convert integer to string
    ; RAX contains the length of the output string

    ; Step 5: Write Output
    mov rdi, OUTPUT_BUFFER                 ; Address of output buffer
    mov rsi, rax                           ; Length of the output string
    call _write                            ; Write to stdout

    ; Write a newline
    mov rdi, CRLF                          ; Address of CRLF
    mov rsi, CRLF_LEN                      ; Length of CRLF
    call _write                            ; Write newline to stdout

    ; Step 6: Exit
    mov rdi, 0                             ; Exit code 0
    call _exit                             ; Terminate the program

string_to_int:
    xor rax, rax                   ; Clear RAX (result)
    xor rcx, rcx                   ; Index register
    xor r9, r9                     ; Sign flag (0 = positive, 1 = negative)

    ; Read first character
    mov bl, [rdi + rcx]            ; Get first character

    ; Skip leading whitespace (optional)
.skip_whitespace:
    cmp bl, ' '
    jne .check_sign
    inc rcx
    mov bl, [rdi + rcx]
    jmp .skip_whitespace

.check_sign:
    ; Check for leading '+' or '-'
    cmp bl, '-'
    je st_neg
    cmp bl, '+'
    je st_pos

st_num:
    ; Parse digits
st_parse:
    ; Check for newline, carriage return, or null terminator
    cmp bl, 10                     ; Newline
    je st_done
    cmp bl, 13                     ; Carriage return
    je st_done
    cmp bl, 0                      ; Null terminator
    je st_done

    ; Check if character is a digit
    cmp bl, '0'
    jb st_invalid
    cmp bl, '9'
    ja st_invalid

    ; Convert ASCII digit to integer
    sub bl, '0'                    ; Convert ASCII to digit (0-9)
    imul rax, rax, 10              ; Multiply current result by 10
    movzx rdx, bl                  ; Move digit to rdx
    add rax, rdx                   ; Add digit to result

    ; Move to next character
    inc rcx
    mov bl, [rdi + rcx]
    jmp st_parse

st_neg:
    mov r9, 1                      ; Set sign flag to negative
    inc rcx                        ; Move to next character
    mov bl, [rdi + rcx]
    jmp st_num

st_pos:
    inc rcx                        ; Move to next character
    mov bl, [rdi + rcx]
    jmp st_num

st_done:
    cmp r9, 1                      ; Check if number is negative
    jne st_end
    neg rax                        ; Negate RAX to make it negative

st_end:
    ret

st_invalid:
    xor rax, rax                   ; Invalid input, set result to 0
    ret

int_to_string:
    ; rax: number to convert
    ; rdi: output buffer

    ; Save callee-saved registers
    push rbp
    mov rbp, rsp

    lea rsi, [TEMP_BUFFER + 128]   ; Point RSI to the end of TEMP_BUFFER
    xor rcx, rcx                   ; Digit count

    ; Check if zero
    cmp rax, 0
    jne its_process

    ; Handle zero separately
    mov byte [rdi], '0'
    mov rax, 1                     ; Length of the string
    jmp its_done

its_process:
    ; Check if number is negative
    xor r10, r10                   ; Sign flag (0 = positive, 1 = negative)
    cmp rax, 0
    jge its_loop                   ; If number >= 0, continue
    mov r10, 1                     ; Set sign flag to negative
    neg rax                        ; Make RAX positive

its_loop:
    xor rdx, rdx                   ; Clear RDX for division
    div qword [ten]                ; Divide RAX by 10
    add rdx, '0'                   ; Convert remainder to ASCII

    dec rsi                        ; Move pointer backward
    mov [rsi], dl                  ; Store digit in TEMP_BUFFER
    inc rcx                        ; Increment digit count

    cmp rax, 0                     ; Check if quotient is zero
    jne its_loop                   ; Continue if not zero

    ; If negative, add '-' to temp buffer
    cmp r10, 1                     ; Check sign flag
    jne its_copy
    dec rsi                        ; Move pointer backward
    mov byte [rsi], '-'            ; Store '-' in TEMP_BUFFER
    inc rcx                        ; Increment digit count

its_copy:
    ; Now copy digits from TEMP_BUFFER to output buffer
    mov rax, rcx                   ; Return length in RAX
    cld                            ; Clear direction flag for forward copying
    rep movsb                      ; Copy RCX bytes from [RSI] to [RDI]

its_done:
    ; Restore callee-saved registers
    mov rsp, rbp
    pop rbp
    ret
