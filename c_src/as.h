#ifndef CB_H
#define CB_H

#include "erl_nif.h"
#include "aerospike.h"

typedef struct connect_args {
    char*   host;
    int     port;
    char*   user;
    char*   pass;
} connect_args_t;

typedef struct key_args {
    char    *ns;
    char    *set;
    char    *key;
} key_args_t;

typedef struct ldt_store_args {
    key_args_t key_args;
    char    *ldt;
    void    *bytes;
    int     nbytes;
    int     timeout;
} store_args_t;


void* cb_connect_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM cb_connect(ErlNifEnv* env, handle_t* handle, void* obj);
void* as_ldt_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM as_ldt_store(ErlNifEnv* env, handle_t* handle, void* obj);

ERL_NIF_TERM return_as_error(ErlNifEnv* env, int const value);
ERL_NIF_TERM return_value(ErlNifEnv* env, void * cookie);

#endif
