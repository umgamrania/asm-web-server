extern  strstr

global  parse_http

section .data
space_str:      db      ' ', 0

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
