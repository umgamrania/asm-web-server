extern  strstr
extern  strlen

global  parse_http
global  resp_400
global  resp_200

section .data
space_str:      db      ' ', 0

; response headers
resp_header_400:        db      "HTTP/1.1 400 BAD REQUEST", 13, 10, 13, 10, 0
resp_header_200:        db      "HTTP/1.1 200 OK", 13, 10, 13, 10, 0

section .text

; --- PARSE_HTTP (char *s, char **method, char **path) ---

parse_http:
        ; Store arguments in stack for later use
        push    rdi
        push    rsi
        push    rdx


        ; find first space
        mov     rsi, space_str
        call    strstr


        ; Return if space not found
        cmp     rax, 0
        jl      .return


        ; replace space with 0
        mov     rdi, qword [rsp + 8 * 2]                        ; load value of s from stack
        mov     byte [rdi + rax], 0                             ; write 0

        ; store method address in **method ptr
        mov     rsi, [rsp + 8]                                  ; load **method from stack
        mov     [rsi], rdi


        ; continue finding next space after first space
        add     rdi, rax
        inc     rdi
        push    rdi                                             ; preserve string pointer
        mov     rsi, space_str
        call    strstr
        pop     rdi

        ; Return if space not found
        cmp     rax, 0
        jl      .return

        ; replace space with 0
        mov     byte [rdi + rax], 0                             ; write 0

        ; store method address in **path ptr
        mov     rsi, [rsp]                                      ; load **path from stack
        mov     [rsi], rdi

        mov     rax, 0

.return:
        pop     rdx
        pop     rsi
        pop     rdi
        ret


; --- RESP_400 (int client_fd) ---

resp_400:
        push    rdi

        mov     rdi, resp_header_400
        call    strlen

        mov     rdx, rax                                ; count
        mov     rsi, resp_header_400                    ; buf
        mov     rdi, [rsp]
        mov     rax, 1
        syscall

        pop     rdi
        mov     rax, 3
        syscall

        ret


; --- RESP_200 (int client_fd) ---

resp_200:
        push    rdi

        mov     rdi, resp_header_200
        call    strlen

        mov     rdx, rax                                ; count
        mov     rsi, resp_header_200
        mov     rdi, [rsp]
        mov     rax, 1
        syscall

        pop     rdi
        mov     rax, 3
        syscall

        ret
