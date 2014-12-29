#ifndef CB_H
#define CB_H

#include "erl_nif.h"
#include <aerospike/aerospike.h>
#include "aerospike.h"
#include <aerospike/aerospike_key.h>
#include <aerospike/aerospike_lset.h>
#include <aerospike/as_error.h>
#include <aerospike/as_record.h>
#include <aerospike/as_status.h>

typedef enum nif_as_ldt_type_e {
    NIF_AS_LDT_LLIST,
    NIF_AS_LDT_LMAP,
    NIF_AS_LDT_LSET,
    NIF_AS_LDT_LSTACK
} nif_as_ldt_type;

typedef struct connect_args {
    char*   host;
    int     port;
    char*   user;
    char*   pass;
} connect_args_t;

typedef struct ldt_store_args {
    as_key      key;
    as_ldt_type ldt_type;
    as_ldt      ldt;
    as_policies policies;
    as_val      *p_value;
} ldt_store_args_t;

typedef struct ldt_get_args {
    as_key      key;
    as_ldt_type ldt_type;
    as_ldt      ldt;
    as_policies policies;
} ldt_get_args_t;

void* as_connect_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM as_connect(ErlNifEnv* env, handle_t* handle, void* obj);
void* as_ldt_store_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM as_ldt_store(ErlNifEnv* env, handle_t* handle, void* obj);
void* as_ldt_get_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM as_ldt_get(ErlNifEnv* env, handle_t* handle, void* obj);

#endif
