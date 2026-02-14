global	print_str
global	print_int
global	print_uint
global  print_char

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

        ret
