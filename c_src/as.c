#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "as.h"
#include <aerospike/as_arraylist_iterator.h>

void *as_connect_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    DEBUG_TRACE("begin connect arg");
    connect_args_t* args = (connect_args_t*)enif_alloc(sizeof(connect_args_t));

    unsigned arg_length;
    if (!enif_get_list_length(env, argv[0], &arg_length)) goto error0;
    args->host = (char *) malloc(arg_length + 1);
    if (!enif_get_string(env, argv[0], args->host, arg_length + 1, ERL_NIF_LATIN1)) goto error1;

    if (!enif_get_int(env, argv[1], &args->port)) goto error2;

    if (!enif_get_list_length(env, argv[2], &arg_length)) goto error2;
    args->user = (char *) malloc(arg_length + 1);
    if (!enif_get_string(env, argv[2], args->user, arg_length + 1, ERL_NIF_LATIN1)) goto error3;

    if (!enif_get_list_length(env, argv[3], &arg_length)) goto error3;
    args->pass = (char *) malloc(arg_length + 1);
    if (!enif_get_string(env, argv[3], args->pass, arg_length + 1, ERL_NIF_LATIN1)) goto error4;
     
    DEBUG_TRACE("end connect arg %s:%d - %s:%s", args->host, args->port, args->user, args->pass);

    return (void*)args;

    error4:
    free(args->pass);
    error3:
    free(args->user);
    error2:
    error1:
    free(args->host);
    error0:
    enif_free(args);

    return NULL;
}

void as_clean_connect_args(ErlNifEnv* env, connect_args_t* args)
{
    DEBUG_TRACE("begin clean connect arg");
    free(args->pass);
    free(args->user);
    free(args->host);
    DEBUG_TRACE("end clean connect arg");
}

ERL_NIF_TERM as_connect(ErlNifEnv* env, handle_t* handle, void* obj)
{
    DEBUG_TRACE("begin connect");

    connect_args_t* args = (connect_args_t*)obj;

    as_status as_res;
	as_error err;
    aerospike *p_as = &(handle->instance);

    // Start with default configuration.
    as_config cfg;
    as_config_init(&cfg);
    as_config_add_host(&cfg, args->host, args->port);
    as_config_set_user(&cfg, args->user, args->pass);

	aerospike_init(p_as, &cfg);

    as_res = aerospike_connect(p_as, &err);
    as_clean_connect_args(env, args);

    if (as_res != AEROSPIKE_OK) {
		aerospike_destroy(p_as);
        return A_AS_ERROR(env, err);
	}

    DEBUG_TRACE("end connect, ok");

    return A_OK(env);
}

as_key* init_key_from_args(ErlNifEnv* env, as_key *key, const ERL_NIF_TERM argv[])
{
    unsigned arg_length;

    // namespace
    if (!enif_get_list_length(env, argv[0], &arg_length)) goto error0;
    char *ns = (char *) malloc(arg_length + 1);
    if (!enif_get_string(env, argv[0], ns, arg_length + 1, ERL_NIF_LATIN1)) goto error1;

    // set
    if (!enif_get_list_length(env, argv[1], &arg_length)) goto error1;
    char *set = (char *) malloc(arg_length + 1);
    if (!enif_get_string(env, argv[1], set, arg_length + 1, ERL_NIF_LATIN1)) goto error2;

    int64_t i64_val;
    ErlNifBinary val_binary;

    if (enif_get_int64(env, argv[2], (ErlNifSInt64*)&i64_val))
    {
        // key : integer
        key = as_key_init_int64(key, ns, set, i64_val);
    }
    else if (enif_get_list_length(env, argv[2], &arg_length))
    {
        // key : string
        char *strValue = (char *) malloc(arg_length + 1);
        if (enif_get_string(env, argv[2], strValue, arg_length + 1, ERL_NIF_LATIN1)) 
        {
            key = as_key_init_strp(key, ns, set, strValue, true);
            if (!key)
            {
                free(strValue);
            }
        } else {
            key = NULL;
            free(strValue);
        }
    }
    else if (enif_inspect_iolist_as_binary(env, argv[2], &val_binary))
    {
        // key : binary
        uint8_t *binValue = malloc(sizeof(uint8_t) * val_binary.size);
        memcpy(binValue, val_binary.data, val_binary.size);

        key = as_key_init_rawp(key, ns, set, binValue, val_binary.size, true);
        if (!key)
        {
            free(binValue);
        }
    }

    error2:
    free(set);
    error1:
    free(ns);
    error0:

    return key;
}

/*
as_ldt_type* init_ldt_store_type_from_arg(ErlNifEnv* env, as_nif_ldt_store_type *p_ldt_store_type, const ERL_NIF_TERM arg_type)
{
    nif_as_ldt_type nif_ldt_type;
    if (!enif_get_uint(env, arg_type, &nif_ldt_type)) return NULL;

    switch (nif_ldt_type)
    {
        case NIF_AS_LDT_LLIST:
            *p_ldt_type = AS_LDT_LLIST;
            break;
        case NIF_AS_LDT_LMAP:
            *p_ldt_type = AS_LDT_LMAP;
            break;
        case NIF_AS_LDT_LSET:
            *p_ldt_type = AS_LDT_LSET;
            break;
        case NIF_AS_LDT_LSTACK:
            *p_ldt_type = AS_LDT_LSTACK;
            break;
        default:
            return NULL;
    }
    return p_ldt_type;
}
*/

as_val* new_val_from_arg(ErlNifEnv* env, const ERL_NIF_TERM argv)
{
    as_val *val;

    // integer
    int64_t i64Value;
    if (enif_get_int64(env, argv, (ErlNifSInt64*)&i64Value))
    {
        val = (as_val *)as_integer_new(i64Value);
        return val;
    }

    // string
    unsigned arg_length;
    if (enif_get_list_length(env, argv, &arg_length))
    {
        char *strValue = (char *) malloc(arg_length + 1);
        if (!enif_get_string(env, argv, strValue, arg_length + 1, ERL_NIF_LATIN1)) goto error1;
        if (!(val=(as_val *)as_string_new(strValue, true))) goto error1;
        return val;

    error1:
        free(strValue);
        return NULL;
    }

    ErlNifBinary val_binary;
    if (enif_inspect_iolist_as_binary(env, argv, &val_binary))
    {
        uint8_t *binValue = malloc(sizeof(uint8_t) * val_binary.size);
        memcpy(binValue, val_binary.data, val_binary.size);
        if (!(val=(as_val *)as_bytes_new_wrap(binValue, val_binary.size, true))) goto error2;
        return val;
        
    error2:
        free(binValue);
        return NULL;
    }

    return NULL;
}

as_ldt* init_ldt_from_arg(ErlNifEnv* env, as_ldt *p_ldt, as_ldt_type ldt_type, const ERL_NIF_TERM arg_ldt)
{
    unsigned arg_length;
    if (!enif_get_list_length(env, arg_ldt, &arg_length)) goto error0;
    char* str_ldt = (char *) malloc(arg_length + 1);
    if (!enif_get_string(env, arg_ldt, str_ldt, arg_length + 1, ERL_NIF_LATIN1)) goto error1;

    p_ldt = as_ldt_init(p_ldt, str_ldt, ldt_type, NULL);

    error1:
    free(str_ldt);
    error0:

    return p_ldt;
}

as_policy_apply* init_policy_apply_from_arg(ErlNifEnv* env, as_policy_apply *p_policy, const ERL_NIF_TERM arg_timeout)
{
    uint32_t ldt_timeout;
    if (!enif_get_uint(env, arg_timeout, &ldt_timeout)) goto error0;

    if (!as_policy_apply_init(p_policy)) goto error0;
    p_policy->timeout = ldt_timeout;

    return p_policy;

    error0:

    return NULL;
}

as_policy_remove* init_policy_remove_from_arg(ErlNifEnv* env, as_policy_remove *p_policy, const ERL_NIF_TERM arg_timeout)
{
    uint32_t ldt_timeout;
    if (!enif_get_uint(env, arg_timeout, &ldt_timeout)) goto error0;

    if (!as_policy_remove_init(p_policy)) goto error0;
    p_policy->timeout = ldt_timeout;

    return p_policy;

    error0:

    return NULL;
}


ERL_NIF_TERM make_nif_term_from_as_val(ErlNifEnv* env, const as_val *p_val)
{
    if(p_val->type == AS_INTEGER)
    {
        return enif_make_int(env, ((as_integer*)p_val)->value);
    }
    else if (p_val->type == AS_STRING)
    {
        as_string *p_str = (as_string *)p_val;
        return enif_make_string(env, p_str->value, ERL_NIF_LATIN1);
    }
    else if(p_val->type == AS_BYTES)
    {
        as_bytes *p_bytes = (as_bytes*)p_val;

        ErlNifBinary val_binary;
        enif_alloc_binary(p_bytes->size, &val_binary);
        memcpy(val_binary.data, p_bytes->value, p_bytes->size);
        return enif_make_binary(env, &val_binary);
    }
    return enif_make_string(env, "unkown", ERL_NIF_LATIN1);
}
