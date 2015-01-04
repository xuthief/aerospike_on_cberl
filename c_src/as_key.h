#ifndef AS_ERL_KEY_H
#define AS_ERL_KEY_H

#include "as.h"

typedef struct key_write_args {
    as_key              key;
    as_policy_write     policy;
    as_val              *p_value;
} key_write_args_t;

typedef struct key_remove_args {
    as_key              key;
    as_policy_remove    policy;
} key_remove_args_t;

typedef struct key_get_args {
    as_key              key;
    as_policy_read      policy;
} key_get_args_t;

void* as_key_remove_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM as_key_remove(ErlNifEnv* env, handle_t* handle, void* obj);

#endif
