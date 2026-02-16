extern  print_sockaddr
extern  print_str
extern  print_char
extern  print_int
extern  alloc
extern  strstr
extern  resp_400
extern  resp_200

extern  parse_http

global  handle_client

section .data
s0:     db      "[CLIENT CONNECTED] ", 0
s1:     db      "BAD REQUEST", 10, 0

section .text

handle_client:
        ; setting up stack
        mov     rbp, rsp
        sub     rsp, 24

        ; Allocate buf
        mov     rdi, 4096
        call    alloc
        push    rax

        ; Read from socket
        mov     rdi, [rsp + 8 * 3]                      ; fd
        mov     rsi, [rsp]                              ; buf
        mov     rdx, 4096                               ; count
        mov     rax, 0
        syscall

        cmp     rax, 0                                  ; exit if no data
        jle      .exit


        ; make room for method and path variables
        sub     rsp, 16

        ; Parse request
        mov     rdi, [rsp + 8 * 2]
        lea     rsi, [rsp + 8]
        mov     rdx, rsp
        call    parse_http

        ; Bad request if parsing fails
        cmp     rax, 0
        jl      .bad


        ; Print client address
        mov     rdi, '['
        call    print_char

        mov     rdi, rsp
        add     rdi, 24
        mov     rsi, 0
        call    print_sockaddr

        mov     rdi, ']'
        call    print_char

        mov     rdi, ' '
        call    print_char



        ; Print method
        mov     rdi, [rsp + 8]
        mov     rsi, 0
        call    print_str

        mov     rdi, ' '
        call    print_char

        ; Print path
        mov     rdi, [rsp]
        mov     rsi, 1
        call    print_str

        mov     rdi, [rsp + 8 * 5]
        call    resp_200

        jmp     .exit

.bad:   mov     rdi, [rsp + 8 * 5]                      ; fd
        call    resp_400

        mov     rdi, s1
        mov     rsi, 0
        call    print_str

.exit:  mov     rdi, 0
        mov     rax, 60
        syscall
