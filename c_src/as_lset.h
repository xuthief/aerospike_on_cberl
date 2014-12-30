#ifndef AS_LSET_H
#define AS_LSET_H

#include "as.h"

typedef struct ldt_store_args {
    as_key      key;
    as_ldt      ldt;
    as_policy_apply policy;
    as_val      *p_value;
} ldt_store_args_t;

typedef struct ldt_get_args {
    as_key      key;
    as_ldt      ldt;
    as_policy_apply policy;
} ldt_get_args_t;

void* as_ldt_store_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM as_ldt_lset_add(ErlNifEnv* env, handle_t* handle, void* obj);
ERL_NIF_TERM as_ldt_lset_remove(ErlNifEnv* env, handle_t* handle, void* obj);

void* as_ldt_get_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM as_ldt_lset_get(ErlNifEnv* env, handle_t* handle, void* obj);
ERL_NIF_TERM as_ldt_lset_size(ErlNifEnv* env, handle_t* handle, void* obj);

#endif
