#ifndef AS_ERL_KEY_H
#define AS_ERL_KEY_H

#include "as.h"

typedef struct key_write_args {
    as_key      key;
    as_policy_write policy;
    as_val      *p_value;
} key_write_args_t;

typedef struct key_remove_args {
    as_key          key;
    as_policy_remove policy;
} key_remove_args_t;

typedef struct get_args {
    as_key          key;
    as_policy_read  policy;
} get_args_t;

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

void* as_key_remove_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM as_key_remove(ErlNifEnv* env, handle_t* handle, void* obj);

#endif
