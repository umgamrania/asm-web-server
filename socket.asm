global  create_socket
global  set_reuseaddr
global  bind
global  listen
global  accept

section .data

sockaddr:
	dw	2		                ; AF_INET
	dw	0x5000		                ; port (80)
	db	0, 0, 0, 0	                ; 0.0.0.0

section .text

; --- CREATE_SOCKET() ---

create_socket:
        mov	rdi, 2		                ; AF_INET
	mov	rsi, 1		                ; SOCK_STREAM
	mov	rdx, 6		                ; IPPROTO_TCP
	mov	rax, 41		                ; socket opcode
	syscall

	ret


; --- SET_REUSEADDR(int sock_fd) ---

set_reuseaddr:                                  ; rdi already contains sock_fd
	mov     rsi, 1                          ; level, SOL_SOCKET
	mov     rdx, 2                          ; SO_REUSEADDR
	push    dword 1                         ; value for SO_REUSEADDR
	mov     r10, rsp
	mov     r8, 4
	mov     rax, 54
	syscall

	add     rsp, 8                          ; remove that dummy 1

	ret


; --- BIND(int sock_fd, sockaddr* addr) ---

bind:                                           ; rdi and rsi are already set by caller
        mov	rdx, 16		                ; length of sockaddr
	mov	rax, 49		                ; bind opcode
	syscall

	ret


; --- LISTEN(int sock_fd, int backlock) ---

listen:                                         ; rdi and rsi are already set by caller
        mov	rax, 50		                ; listen opcode
	syscall

	ret


; --- ACCEPT(int sock_fd, sockaddr *remote_addr) ---

accept:                                         ; rdi and rsi are already set by caller
        mov     rdx, 0                          ; remote_addr len not required
        mov	rax, 43		                ; accept opcode
	syscall

	ret
