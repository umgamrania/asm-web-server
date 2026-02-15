global  _start

extern  print_int
extern  print_uint
extern  print_str
extern  print_char
extern  print_sockaddr

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
success_socket: db      "Socket created!", 10, 0

; msg
msg_init:       db      "Setting up socket...", 10, 0
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
        sub     rsp, 24
        mov     rdi, rsp
        call    print_sockaddr

        mov     rdi, 0
        mov     rax, 60
        syscall

_start: mov     rdi, msg_init                           ; Printing init msg
        mov     rsi, 0
        call    print_str

        call    setup_socket                            ; Setting up socket
        cmp     rax, 0
        jl      EXIT


.loop:                                                  ; Socket accept loop
        ; Print wait msg
        mov     rdi, msg_wait_client
        mov     rsi, 0
        call    print_str

        ; ACCEPT
        mov     rdi, [sock_fd]                          ; sock_fd is set by setup_socket
        mov     rsi, client_sockaddr
        call    accept
        push    rax                                     ; Store socket_fd in stack


        ; Allocate Stack for thread
        mov     rdi, 1024
        call    alloc
        add     rax, 1024                               ; rax now points to bottom of new stack

        ; Push socket_fd on new stack
        sub     rax, 8                                  ; allocate room for socket_fd
        pop     rbx                                     ; Temporarily store socket_fd in rbx
        mov     qword [rax], rbx                        ; store socket_fd on new stack

        ; Push client sockaddr on new stack
        sub     rax, 16
        movdqu  xmm0, [client_sockaddr]
        movdqu  [rax], xmm0


        ; Create thread
        add     rax, 24                                 ; Restore rax to base of new stack

        mov     rdi, 0x10d00                            ; flags (CLONE_VM | CLONE_FILES | CLONE_THREAD | CLONE_SIGHAND)
        mov     rsi, rax                                ; new stack ptr
        mov     rax, 56                                 ; CLONE opcode
        syscall

        cmp     rax, 0                                  ; Compare return value of clone
        je      handle_client                           ; Child process receives 0

        jmp     .loop                                   ; Parent process continues loop

EXIT:   mov     rdi, 0
        mov     rax, 60
        syscall
