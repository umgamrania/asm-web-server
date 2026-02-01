global  _start

extern  print_int
extern  print_str

extern  create_socket
extern  set_reuseaddr
extern  bind
extern  listen
extern  accept

section .data

; err messages
err_socket:     db      "Failed to create socket!", 10, 0
err_reuse:      db      "Failed to setsockopt!", 10, 0
err_bind:       db      "Failed to bind!", 10, 0
err_listen:     db      "Failed to call listen!", 10, 0

; success messages
success_socket: db      "Socket created!!!!", 10, 0

sockaddr:
	dw	        2		                ; AF_INET
	dw	        0x901F		                ; port (8080)
	db	        127, 0, 0, 1	                ; 127.0.0.1

section .bss
sock_fd:                resq    1
client_sockaddr:        resb    16

section .text

setup_socket:

        ; CREATE SOCKET
        call    create_socket
        cmp     rax, 0
        jl      .fail_socket

        mov     [sock_fd], rax                  ; store socket fd in memory

        ; SETSOCKOPT
        mov     rdi, rax                        ; sock_fd, cuz still in rax
        call    set_reuseaddr
        cmp     rax, 0
        jl      .fail_reuse

        ; BIND
        mov     rdi, [sock_fd]
        mov     rsi, sockaddr
        call    bind
        cmp     rax, 0
        jl      .fail_bind

        ; LISTEN
        mov     rdi, [sock_fd]
        mov     rsi, 8
        call    listen
        cmp     rax, 0
        jl      .fail_listen

        mov     rax, 0                          ; success
        ret

.fail_socket:
        mov     rdi, err_socket
        mov     rsi, 0
        call    print_str
        jmp     EXIT

.fail_reuse:
        mov     rdi, err_reuse
        mov     rsi, 0
        call    print_str
        jmp     EXIT

.fail_bind:
        mov     rdi, err_bind
        mov     rsi, 0
        call    print_str
        jmp     EXIT

.fail_listen:
        mov     rdi, err_listen
        mov     rsi, 0
        call    print_str
        jmp     EXIT


_start: call    setup_socket
        cmp     rax, 0
        jl      EXIT

        mov     rdi, success_socket
        mov     rsi, 0
        call    print_str

        mov     rdi, [sock_fd]
        mov     rsi, 0
        call    accept

        mov     rdi, rax
        call    print_int

EXIT:   mov     rdi, 0
        mov     rax, 60
        syscall
