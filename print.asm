global	print_str
global	print_int
global	print_uint
global  print_char
global  print_sockaddr

extern	itoa
extern	uitoa
extern	strlen

section	.bss
print_int_buf:	resb	32

section	.text

; --- PRINT_STR (char *s, bool new_line) ---

print_str:
        push	rsi			; push rsi for later use
	push	rdi			; push *s before strlen
	call	strlen
	pop	rdi

	mov	rsi, rdi		; *s
	mov	rdx, rax		; move return value of strlen to rdx
	mov	rdi, 1			; stdout
	mov	rax, 1			; write opcode
	syscall

	pop	rsi
	cmp	rsi, 0
	je	.end			; just return if new_line is 0

	push	0xA			; push new line string to stack
	mov	rdi, 1			; stdout
	mov	rsi, rsp		; buf
	mov	rdx, 2			; count
	mov	rax, 1			; write opcode
	syscall

	add	rsp, 8			; remove new line char from stack

.end:	ret


; --- PRINT_INT (int i, bool new_line) ---

print_int:
        push	rsi			; push rsi for later use

	mov	rsi, print_int_buf	; convert int to ascii and store in buf
	call	itoa

	pop	rsi			; restore new_line value
	mov	rdi, print_int_buf	; print converted buf
	call	print_str

	ret


; --- print_uint (int i, bool new_line) ---

print_uint:
	push	rsi			; push rsi for later use

	mov	rsi, print_int_buf	; convert int to string in buf
	call	uitoa

	pop	rsi
	mov	rdi, print_int_buf
	call	print_str

	ret


; --- PRINT_CHAR (char c) ---

print_char:
        dec     rsp                     ; storing character in stack cuz write needs buffer
        mov     byte [rsp], dil

        mov     rdi, 1                  ; stdout
        mov     rsi, rsp                ; buf
        mov     rdx, 1                  ; count
        mov     rax, 1
        syscall
        inc     rsp
        ret


; --- PRINT_SOCKADDR (sockaddr *s, bool print_port) ---

print_sockaddr:
        mov     r12, rdi                ; store ptr in a callee-saved register
        mov     r13, rsi                ; store print_port
        mov     rbx, 4                  ; counter

.loop:  movzx   rdi, byte [r12 + rbx]   ; load and print octet
        mov     rsi, 0
        call    print_uint

        inc     rbx                     ; increment counter and break if done
        cmp     rbx, 8
        jge     .end_loop

        mov     rdi, '.'                ; print octet seperator
        call    print_char

        jmp     .loop

.end_loop:
        cmp     r13, 0
        je      .end

        ; PRINTING PORT
        mov     rdi, ':'
        call    print_char

        movzx   rax, word [r12 + 2]     ; load port from struct
        xchg    al, ah                  ; endian-ness mess
        mov     rdi, rax

        mov     rsi, 0
        call    print_uint

.end:   ret
