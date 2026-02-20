extern  strstr
extern  strlen

global  parse_http
global  resp_400
global  resp_404
global  resp_200

section .data
space_str:      db      ' ', 0

; response headers
resp_header_400:        db      "HTTP/1.1 400 BAD REQUEST", 13, 10, 13, 10, 0
resp_header_404:        db      "HTTP/1.1 404 NOT FOUND", 13, 10, 13, 10, 0
resp_header_200:        db      "HTTP/1.1 200 OK", 13, 10, 13, 10, 0

section .text

; ***
;  I am aware that this function is messy and can clearly be improved,
; but it worked on first attempt :)
; ***
;
; --- PARSE_HTTP (char *s, char **method, char **path) ---

parse_http:
        push    rbp
        mov     rbp, rsp

        push    rdx
        push    rsi
        push    rdi

        ; rdi already contains *s
        ; Finding first space that seperates method and path
        mov     rsi, space_str
        call    strstr

        cmp     rax, 0
        jl      .bad

        ; get start of str and terminate at first space
        pop     rdi
        mov     byte [rdi + rax], 0                     ; terminate after method

        pop     rsi                                     ; pop **method from stack
        mov     [rsi], rdi                              ; store start of buf at **method

        add     rdi, rax                                ; set start address to after terminator
        inc     rdi
        push    rdi                                     ; store new start of buf

        ; find second space
        mov     rsi, space_str
        call    strstr

        cmp     rax, 0
        jl      .bad

        pop     rdi
        mov     byte [rdi + rax], 0

        pop     rdx
        mov     [rdx], rdi
        jmp     .end

.bad:   mov     rax, -1

.end:   leave
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


; --- RESP_404 (int client_fd) ---

resp_404:
        push    rdi

        mov     rdi, resp_header_404
        call    strlen

        mov     rdx, rax                                ; count
        mov     rsi, resp_header_404                    ; buf
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

        ret
