#ifndef AS_H
#define AS_H

#include "erl_nif.h"
#include <aerospike/aerospike.h>
#include "aerospike.h"
#include <aerospike/aerospike_key.h>
#include <aerospike/aerospike_lset.h>
#include <aerospike/as_error.h>
#include <aerospike/as_record.h>
#include <aerospike/as_status.h>

#if 1
#define DEBUG_TRACE(fmt, ...) do { fprintf(stderr, "[TRACE] %s [Line %d] "fmt"\n", __PRETTY_FUNCTION__, __LINE__,  ##__VA_ARGS__);} while(0)
#else
#define DEBUG_TRACE(fmt, ...) 
#endif

typedef enum as_nif_ldt_store_type_e {
    AS_NIF_LDT_LLIST_STORE,
    AS_NIF_LDT_LMAP_STORE,
    AS_NIF_LDT_LSET_ADD,
    AS_NIF_LDT_LSET_REMOVE,
    AS_NIF_LDT_LSTACK_STORE
} as_nif_ldt_store_type;

typedef enum as_nif_ldt_get_type_e {
    AS_NIF_LDT_LLIST_GET,
    AS_NIF_LDT_LMAP_GET,
    AS_NIF_LDT_LSET_GET,
    AS_NIF_LDT_LSET_SIZE,
    AS_NIF_LDT_LSTACK_GET
} as_nif_ldt_get_type;

typedef struct connect_args {
    char*   host;
    int     port;
    char*   user;
    char*   pass;
} connect_args_t;

as_key* init_key_from_args(ErlNifEnv* env, as_key *key, const ERL_NIF_TERM argv[]);
as_val* new_val_from_arg(ErlNifEnv* env, const ERL_NIF_TERM argv);
as_ldt* init_ldt_from_arg(ErlNifEnv* env, as_ldt *p_ldt, as_ldt_type ldt_type, const ERL_NIF_TERM arg_ldt);
as_policy_apply* init_policy_apply_from_arg(ErlNifEnv* env, as_policy_apply *p_policy, const ERL_NIF_TERM arg_timeout);

ERL_NIF_TERM make_nif_term_from_as_val(ErlNifEnv* env, const as_val *p_val);

void* as_connect_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM as_connect(ErlNifEnv* env, handle_t* handle, void* obj);

#endif
