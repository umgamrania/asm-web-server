extern  print_sockaddr
extern  print_str
extern  print_int
extern  alloc

global  handle_client

section .data
s0:     db      "[CLIENT CONNECTED] ", 0

section .text

handle_client:
        ; setting up stack
        mov     rbp, rsp
        sub     rsp, 24


        ; Print client ip
        mov     rdi, s0
        mov     rsi, 0
        call    print_str
        mov     rdi, rsp
        call    print_sockaddr


        ; Allocate buf
        mov     rdi, 4096
        call    alloc
        push    rax

.recv_loop:
        ; Read from socket
        mov     rdi, [rsp + 8 * 3]
        mov     rsi, rsp
        mov     rdx, 4096
        mov     rax, 0
        syscall

        cmp     rax, 0
        jle      .exit


        ; Print request
        mov     rdi, 1
        mov     rsi, rsp
        mov     rdx, rax
        mov     rax, 1
        syscall


        jmp     .recv_loop


.exit:  mov     rdi, 0
        mov     rax, 60
        syscall
