global	strlen
global	strcmp
global	strncmp
global	strrev
global	strstr
global	atoi
global	itoa
global	uitoa
global  alloc
global  free

section	.text

; --- STRLEN (char *s) ---

strlen:	mov	rcx, rdi		; store start addr in rcx

.loop:	cmp	byte [rdi], 0		; check for string terminator
	je	.end			; break loop if end of string
	inc	rdi			; increment *s ptr
	jmp	.loop			; continue loop

.end:	sub	rdi, rcx		; subtract start addr from end addr
	mov	rax, rdi		; store return value in rax

	ret


; --- STRCMP (char *s1, char *s2) ---

strcmp:

.loop:	mov	al, byte [rdi]		; load character from s1
	mov	cl, byte [rsi]		; load character from s2

	cmp	al, 0			; check for string terminator
	je	.end			; break loop if end of string

	cmp	al, cl			; compare characters
	jne	.end			; break loop if not equal

	inc	rdi			; increment *s1
	inc	rsi			; increment *s2
	jmp	.loop			; continue loop

.end:	sub	al, cl			; subtract for difference
	movzx	rax, al			; store return value in rax

	ret


; --- STRNCMP (char *s1, char *s2, int n) ---

strncmp:
	xor	rax, rax
	xor	rcx, rcx

.loop:	cmp	rdx, 0			; check if n is 0
	je	.end

	mov	al, byte [rdi]		; load character from s1
	mov	cl, byte [rsi]		; load character from s2

	cmp	al, 0			; check for string terminator
	je	.end			; break loop if end of string

	cmp	al, cl			; compare characters
	jne	.end			; break if not equal

	inc	rdi
	inc	rsi
	dec	rdx
	jmp	.loop

.end:	sub	al, cl			; subtract for difference
	movzx	rax, al			; store difference in rax

	ret


; --- STRSTR (char *haystack, char *needle) ---

strstr:	push	rbx			; preserve rbx

        push    rdi                     ; store haystack in memory
        push    rsi                     ; store needle ptr in memory

	mov	rdi, rsi		; load needle ptr to rdi
	call	strlen
	push	rax	                ; store needle length

	mov	rbx, 0			; init counter
	xor	rdi, rdi

.loop:	mov	rdi, [rsp + 16]         ; load character at haystack ptr
	mov	rsi, [rsp + 8]          ; load needle ptr
	mov	rdx, [rsp]              ; load needle length

	cmp	byte [rdi], 0           ; check for end of string
	je	.notfound

	call	strncmp                 ; compare hay from current char and needle
	test	rax, rax                ; check if match
	jz	.found

	inc	qword [rsp + 16]        ; increment haystack ptr
	inc	rbx                     ; increment counter

	jmp	.loop

.notfound:
        add     rsp, 24                 ; collapse stack frame
	pop	rbx                     ; restore rbx
	mov	rax, -1                 ; return value
	ret

.found: add     rsp, 24                 ; collapse stack frame
        mov	rax, rbx
	pop	rbx
	ret


; --- ATOI (char *s) ---

atoi:	push	rdi			; store start addr to later check for '-'

	cmp	byte [rdi], '-'		; check if negative
	jne	.positive
	inc	rdi			; skip one char if negative

.positive:
	xor	rdx, rdx		; clear rdx
	xor	rcx, rcx		; clear rcx

.loop:	mov	cl, byte [rdi]		; load character

        cmp     cl, 10                  ; check for new line
        je      .end_loop

	cmp	cl, 0			; check for string terminator
	je	.end_loop		; break loop of end of string

	imul	rdx, 10
	sub	cl, '0'			; ascii to int
	add	rdx, rcx

	inc	rdi			; increment *s ptr
	jmp	.loop			; continue loop

.end_loop:
	mov	rax, rdx		; store return value in rax

	pop	rdi			; restore original start addr of string
	cmp	byte [rdi], '-'		; check if '-'
	jne	.end

	neg	rax

.end:	ret


; --- STRREV (char *s) ---

strrev:	push	rdi			; store rdi to return at the end
	push	rdi			; preserve rdi to use after strlen
	call	strlen
	mov	rcx, rax		; store length of string in rcx
	dec	rcx			; decrement 1 for last character index

	pop	rdi			; restore original start addr of string
	add	rcx, rdi		; rcx now holds end of string addr

.loop:	cmp	rdi, rcx		; check left < right
	jge	.end

	mov	al, byte [rdi]		; load character at left
	mov	dl, byte [rcx]		; load character at right
	mov	byte [rdi], dl		; swap
	mov	byte [rcx], al

	inc	rdi			; move pointers
	dec	rcx

	jmp	.loop			; continue loop

.end:	pop	rax			; pop previous rdi value into rax
	ret



; --- ITOA (int i, char *buf) ---

itoa:	push	rsi			; store buf addr to return
	cmp	rdi, 0			; check if negative
	jge	.positive

	mov	byte [rsi], '-'		; add - in buf if negative
	inc	rsi
	neg	rdi			; rest of the number can be treated as positive

.positive:
	call	uitoa			; convert positive number to ascii
	pop	rax			; restore buffer start addr to return
	ret

; --- UITOA (int i, char *buf) ---

uitoa:	push	rsi			; push buffer start address to stack

	mov	r9, 10			; base for division
	mov	rax, rdi		; load number to rax for division

.loop:	xor	rdx, rdx		; clear rdx for division
	div	r9

	add	rdx, '0'		; convert remainder to ascii
	mov	byte [rsi], dl		; store ascii in buffer
	inc	rsi			; increment buffer ptr

	test	rax, rax		; stop if number is 0
	jg	.loop

.end:	mov	byte [rsi], 0		; add string terminator

	pop	rdi			; pop buffer start addr into rdi
	call	strrev

	ret


; --- ALLOC(int size) ---

alloc:
        mov     rsi, rdi                        ; length
        mov     rdi, 0                          ; target addr
        mov     rdx, 0x3                        ; prot (PROT_READ | PROT_WRITE)
        mov     r10, 0x22                       ; flags (MAP_PRIVATE | MAP_ANONYMOUS)
        mov     r8, -1                          ; fd
        mov     r9, 0                           ; offset
        mov     rax, 9                          ; mmap opcode
        syscall

        ret


; --- FREE(void *ptr, int size) ---

free:   mov     rax, 0x0b                       ; munmap opcode
        syscall

        ret
