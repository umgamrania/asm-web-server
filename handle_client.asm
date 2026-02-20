extern  print_sockaddr
extern  print_str
extern  print_char
extern  print_int
extern  alloc
extern  strstr
extern  strcmp
extern  get_filesize
extern  resp_400
extern  resp_404
extern  resp_200

extern  parse_http

global  handle_client

section .data
s0:     db      "[CLIENT CONNECTED] ", 0
s1:     db      "BAD REQUEST", 10, 0
s2:     db      13, 10, 13, 10, 0
s3:     db      "GET", 0
s4:     db      "Method not allowed", 10, 0

section .text

; --- RECV_REQ (int sock_fd) ---

recv_req:
        ; prologue
        push    rbp
        mov     rbp, rsp

        push    rdi                             ; socket_fd
        mov     r12, 4096                       ; count for read (buf size)

        ; allocate memory for reqest
        mov     rdi, r12
        call    alloc
        push    rax                             ; buf start addr

        mov     r13, rax                        ; start of buf to return

.loop:  mov     rdi, [rsp + 8]                  ; socket_fd
        mov     rsi, [rsp]                      ; buf
        mov     rdx, r12                        ; count
        mov     rax, 0                          ; read opcode
        syscall

        sub     r12, rax                        ; remaining space in buf

        ; check if received block ends with \r\n\r\n
        mov     rdi, [rsp]
        mov     rsi, s2
        call    strstr

        ; if positive, then end
        cmp     rax, 0
        jg      .done

        ; add no. of bytes read to start address to continue writing at
        add     [rsp], rax
        jmp     .loop

.done:  mov     rax, r13                        ; return value
        leave
        ret


; --- SEND_FILE(int sock_fd, char *path) ---

send_file:
        push    rbp
        mov     rbp, rsp

        push    rdi
        push    rsi

        ; try to open file
        mov     rdi, rsi                        ; path
        mov     rsi, 0                          ; O_RDONLY
        mov     rdx, 0                          ; no extra modes
        mov     rax, 2
        syscall

        cmp     rax, 0
        jl      .not_found

        push    rax                             ; store file descriptor

        ; at this point everything is good, so we send 200 OK
        mov     rdi, [rsp + 8 * 2]
        call    resp_200

        mov     rdi, [rsp + 8]
        call    get_filesize

        mov     r10, rax                        ; count
        mov     rdi, [rsp + 8 * 2]              ; out_fd
        mov     rsi, [rsp]                      ; in_fd
        mov     rdx, 0                          ; offset
        mov     rax, 40
        syscall

        jmp     .exit

.not_found:
        mov     rdi, [rsp + 8]
        call    resp_404

.exit:  leave
        ret


handle_client:
        ; setup stack
        mov     rbp, rsp
        sub     rsp, 24

        mov     rdi, [rsp + 8 * 2]              ; socket_fd
        call    recv_req

        sub     rsp, 16                         ; make room for two pointers

        mov     rdi, rax                        ; *req
        mov     rsi, rsp                        ; **method
        lea     rdx, [rsp + 8]                  ; **path
        call    parse_http

        cmp     rax, 0                          ; check if bad request
        jl      .bad

        mov     rdi, [rsp]                      ; check method
        mov     rsi, s3
        call    strcmp

        cmp     rax, 0                          ; if method not allowed
        jne     .notal

        mov     rdi, [rsp + 8 * 4]              ; sock_fd
        mov     rsi, [rsp + 8]                  ; path
        inc     rsi                             ; remove forward slash
        call    send_file

        jmp     .exit

.bad:   mov     rdi, [rsp + 8 * 4]
        call    resp_400
        jmp     .exit

.notal: mov     rdi, s4
        mov     rsi, 0
        call    print_str

.exit:  mov     rdi, [rsp + 8 * 4]              ; close socket
        mov     rax, 3
        syscall

        mov     rdi, 0
        mov     rax, 60
        syscall
