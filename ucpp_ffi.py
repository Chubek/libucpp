# build_ucpp_ffi.py
from cffi import FFI

ffi = FFI()

ffi.cdef(
    r"""
    typedef unsigned long size_t;

    typedef struct lexer_state lexer_state;
    typedef struct token token;
    typedef struct token_fifo token_fifo;
    typedef struct garbage_fifo garbage_fifo;
    typedef struct hash_item_header hash_item_header;

    struct comp_token_fifo {
        size_t length;
        size_t rp;
        unsigned char *t;
    };

    struct assert {
        hash_item_header head;
        size_t nbval;
        struct token_fifo *val;
    };

    struct macro {
        hash_item_header head;
        int narg;
        char **arg;
        int nest;
        int vaarg;
    #ifdef LOW_MEM
        struct comp_token_fifo cval;
    #else
        struct token_fifo val;
    #endif
    };

    void ucpp_init_cppm(void);
    void ucpp_put_char(struct lexer_state *, unsigned char);
    void ucpp_discard_char(struct lexer_state *);
    int ucpp_next_token(struct lexer_state *);
    int ucpp_grap_char(struct lexer_state *);
    int ucpp_space_char(int);

    int ucpp_cmp_token_list(struct token_fifo *, struct token_fifo *);
    int ucpp_handle_assert(struct lexer_state *);
    int ucpp_handle_unassert(struct lexer_state *);
    struct assert *ucpp_get_assertion(char *);
    void ucpp_wipe_assertions(void);

    void ucpp_print_token(struct lexer_state *, struct token *, long);
    int ucpp_handle_define(struct lexer_state *);
    int ucpp_handle_undef(struct lexer_state *);
    int ucpp_handle_ifdef(struct lexer_state *);
    int ucpp_handle_ifndef(struct lexer_state *);
    int ucpp_substitute_macro(
        struct lexer_state *,
        struct macro *,
        struct token_fifo *,
        int,
        int,
        long
    );
    struct macro *ucpp_get_macro(char *);
    void ucpp_wipe_macros(void);

    extern struct lexer_state ucpp_dsharp_lexer;
    extern char ucpp_compile_time[];
    extern char ucpp_compile_date[];

    unsigned long ucpp_strtoconst(char *);
    unsigned long ucpp_eval_expr(struct token_fifo *, int *, int);
    extern long ucpp_eval_line;

    char *ucpp_token_name(struct token *);
    void ucpp_throw_away(struct garbage_fifo *, char *);
    void ucpp_garbage_collect(struct garbage_fifo *);
    void ucpp_init_buf_lexer_state(struct lexer_state *, int);

    void ucpp_ouch(const char *, ...);
    void ucpp_error(int, const char *, ...);
    void ucpp_warning(int, const char *, ...);
    """
)

ffi.set_source(
    "_ucpp_cffi",
    """
    #include "ucppi.h"
    """,
    libraries=["ucpp"],
    include_dirs=[],
)

if __name__ == "__main__":
    ffi.compile(verbose=True)
