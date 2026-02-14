global  _start

extern  print_int
extern  print_str

extern  create_socket
extern  set_reuseaddr
extern  bind
extern  listen
extern  accept
extern  alloc

section .data

; err messages
err_socket:     db      "Failed to create socket!", 10, 0
err_reuse:      db      "Failed to setsockopt!", 10, 0
err_bind:       db      "Failed to bind!", 10, 0
err_listen:     db      "Failed to call listen!", 10, 0

; success messages
success_socket: db      "Socket created!!!!", 10, 0

; msg
msg_wait_client:
                db      "Waiting for client...", 10, 0

sockaddr:
	dw	        2		                ; AF_INET
	dw	        0x901F		                ; port (8080)
	db	        127, 0, 0, 1	                ; 127.0.0.1

section .bss
sock_fd:                resq    1
remote_fd:              resq    1
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


handle_client:
        mov     rdi, qword [rsp - 8]
        mov     rsi, 1
        call    print_int

        mov     rdi, 0
        mov     rax, 60
        syscall

_start: call    setup_socket
        cmp     rax, 0
        jl      EXIT

        mov     rdi, success_socket
        mov     rsi, 0
        call    print_str

.loop:  mov     rdi, msg_wait_client
        mov     rsi, 0
        call    print_str

        mov     rdi, [sock_fd]
        mov     rsi, 0
        call    accept
        push    rax

        mov     rdi, 256
        call    alloc
        add     rax, 256

        pop     rbx
        mov     qword [rax - 8], rbx

        mov     rdi, 0x10d00                    ; flags (CLONE_VM | CLONE_FILES | CLONE_THREAD | CLONE_SIGHAND)
        mov     rsi, rax                        ; stack ptr
        mov     rax, 56                         ; clone opcode
        syscall

        cmp     rax, 0
        je      handle_client

        jmp     .loop

EXIT:   mov     rdi, 0
        mov     rax, 60
        syscall
