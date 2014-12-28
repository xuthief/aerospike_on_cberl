#include <libaerospike/aerospike.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "callbacks.h"
#include "as.h"

char *format_as_error(char *api, as_error *err) {
    static char str_error[512];
    sprintf(str_error, "%s: %d - %s", api, err.code, err.message);
    return str_error;
}

void *as_connect_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    connect_args_t* args = (connect_args_t*)enif_alloc(sizeof(connect_args_t));

    unsigned arg_length;
    if (!enif_get_list_length(env, argv[0], &arg_length)) goto error0;
    args->host = (char *) malloc(arg_length + 1);
    if (!enif_get_string(env, argv[0], args->host, arg_length + 1, ERL_NIF_LATIN1)) goto error1;

    if (!enif_get_int(env, argv[1], args->port, arg_length + 1, ERL_NIF_LATIN1)) goto error2;

    if (!enif_get_list_length(env, argv[2], &arg_length)) goto error2;
    args->user= (char *) malloc(arg_length + 1);
    if (!enif_get_string(env, argv[2], args->user, arg_length + 1, ERL_NIF_LATIN1)) goto error3;

    if (!enif_get_list_length(env, argv[3], &arg_length)) goto error3;
    args->pass= (char *) malloc(arg_length + 1);
    if (!enif_get_string(env, argv[3], args->pass, arg_length + 1, ERL_NIF_LATIN1)) goto error4;
     
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

ERL_NIF_TERM as_connect(ErlNifEnv* env, handle_t* handle, void* obj)
{
    connect_args_t* args = (connect_args_t*)obj;

    as_status as_res;
	as_error err;
    aerospike *p_as = &(handle->instance);

    // Start with default configuration.
    as_config cfg;
    as_config_init(&cfg);
    as_config_add_host(&cfg, args->host, args->port);
    as_config_set_user(&cfg, args->user, args->pass);

    create_options.v.v0.passwd = args->pass;

    as_res = aerospike_connect(p_as, &err);

    free(args->host);
    free(args->user);
    free(args->pass);

    if (as_res != AEROSPIKE_OK) {
		aerospike_destroy(p_as);
        return enif_make_tuple2(env, enif_make_atom(env, "error"),
                enif_make_string(env, format_as_error("aerospike_connect", err), ERL_NIF_LATIN1));
	}

    return enif_make_atom(env, "ok");
}

void* cb_store_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    store_args_t* args = (store_args_t*)enif_alloc(sizeof(store_args_t));

    ErlNifBinary value_binary;
    ErlNifBinary key_binary;

    if (!enif_get_int(env, argv[0], &args->operation)) goto error0;
    if (!enif_inspect_iolist_as_binary(env, argv[1], &key_binary)) goto error0;
    if (!enif_inspect_iolist_as_binary(env, argv[2], &value_binary)) goto error0;

    args->nkey = key_binary.size;
    args->nbytes = value_binary.size;
    args->key = (char*)malloc(key_binary.size);
    args->bytes = (char*)malloc(value_binary.size);
    memcpy(args->bytes, value_binary.data, value_binary.size);
    memcpy(args->key, key_binary.data, key_binary.size);

    if (!enif_get_uint(env, argv[3], &args->flags)) goto error1;
    if (!enif_get_int(env, argv[4], &args->exp)) goto error1;
    if (!enif_get_uint64(env, argv[5], (ErlNifUInt64*)&args->cas)) goto error1;

    return args;

    error1:
    free(args->bytes);
    free(args->key);
    error0:
    enif_free(args);

    return NULL;
}

ERL_NIF_TERM cb_store(ErlNifEnv* env, handle_t* handle, void* obj)
{
    store_args_t* args = (store_args_t*)obj;

    struct libaerospike_callback cb;

    lcb_error_t ret;

    lcb_store_cmd_t cmd;
    const lcb_store_cmd_t *commands[1];

    commands[0] = &cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.v.v0.operation = args->operation;
    cmd.v.v0.key = args->key;
    cmd.v.v0.nkey = args->nkey;
    cmd.v.v0.bytes = args->bytes;
    cmd.v.v0.nbytes = args->nbytes;
    cmd.v.v0.flags = args->flags;
    cmd.v.v0.exptime = args->exp;
    cmd.v.v0.cas = args->cas;

    ret = lcb_store(handle->instance, &cb, 1, commands);
    
    free(args->key);
    free(args->bytes);
    
    if (ret != LCB_SUCCESS) {
        return return_lcb_error(env, ret);
    }

    lcb_wait(handle->instance);

    if (cb.error != LCB_SUCCESS) {
        return return_lcb_error(env, cb.error);
    }
    return A_OK(env);
}

void* cb_mget_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    mget_args_t* args = (mget_args_t*)enif_alloc(sizeof(mget_args_t));

    ERL_NIF_TERM* currKey;
    ERL_NIF_TERM tail;
    ErlNifBinary key_binary;

    if (!enif_get_list_length(env, argv[0], &args->numkeys)) goto error0;     
    args->keys = malloc(sizeof(char*) * args->numkeys);
    args->nkeys = malloc(sizeof(size_t) * args->numkeys);
    currKey = malloc(sizeof(ERL_NIF_TERM));
    tail = argv[0];
    int i = 0;
    while(0 != enif_get_list_cell(env, tail, currKey, &tail)) {
        if (!enif_inspect_iolist_as_binary(env, *currKey, &key_binary)) goto error1;
        args->keys[i] = malloc(sizeof(char) * key_binary.size);
        memcpy(args->keys[i], key_binary.data, key_binary.size);
        args->nkeys[i] = key_binary.size;
        i++;
    }
    
    if (!enif_get_int(env, argv[1], &args->exp)) goto error1;
    if (!enif_get_int(env, argv[2], &args->lock)) goto error1;
    if (!enif_get_int(env, argv[3], &args->gettype)) goto error1;

    free(currKey);

    return (void*)args;

    int f = 0;

    error1:
    for(f = 0; f < i; f++) {
        free(args->keys[f]);
    }
    free(args->keys);
    free(args->nkeys);
    free(currKey);
    error0:
    enif_free(args);

    return NULL;
}

ERL_NIF_TERM cb_mget(ErlNifEnv* env, handle_t* handle, void* obj)
{
    mget_args_t* args = (mget_args_t*)obj;

    struct libaerospike_callback_m cb; 

    lcb_error_t ret;
    
    ERL_NIF_TERM* results;
    ERL_NIF_TERM returnValue;
    ErlNifBinary databin;
    ErlNifBinary key_binary;
    unsigned int numkeys = args->numkeys;
    void** keys = args->keys;
    size_t* nkeys = args->nkeys;
    int exp = args->exp;
    int lock = args->lock;
    int gettype = args->gettype;
    int i = 0;

    cb.currKey = 0;
    cb.ret = malloc(sizeof(struct libaerospike_callback*) * numkeys);


    const lcb_get_cmd_t* commands[numkeys];
    i = 0;
    for (; i < numkeys; i++) {
      lcb_get_cmd_t *get = calloc(1, sizeof(*get));
      get->version = 0;
      get->v.v0.key = keys[i];
      get->v.v0.nkey = nkeys[i];
      get->v.v0.exptime = exp;
      get->v.v0.lock = lock;
      get->v.v0.gettype = gettype;
      commands[i] = get;
    }

    ret = lcb_get(handle->instance, &cb, numkeys, commands);

    if (ret != LCB_SUCCESS) {
        return return_lcb_error(env, ret);
    }
    lcb_wait(handle->instance);

    results = malloc(sizeof(ERL_NIF_TERM) * numkeys);
    i = 0; 
    for(; i < numkeys; i++) {
        enif_alloc_binary(cb.ret[i]->nkey, &key_binary);
        memcpy(key_binary.data, cb.ret[i]->key, cb.ret[i]->nkey);
        if (cb.ret[i]->error == LCB_SUCCESS) {
            enif_alloc_binary(cb.ret[i]->size, &databin);
            memcpy(databin.data, cb.ret[i]->data, cb.ret[i]->size);
            results[i] = enif_make_tuple4(env, 
                    enif_make_uint64(env, cb.ret[i]->cas), 
                    enif_make_int(env, cb.ret[i]->flag), 
                    enif_make_binary(env, &key_binary),
                    enif_make_binary(env, &databin));
            free(cb.ret[i]->data);
        } else {
            results[i] = enif_make_tuple2(env, 
                    enif_make_binary(env, &key_binary),
                    return_lcb_error(env, cb.ret[i]->error));
        }
        free(cb.ret[i]->key);
        free(cb.ret[i]);
        free(keys[i]);
        free((lcb_get_cmd_t*) commands[i]);
    }

    returnValue = enif_make_list_from_array(env, results, numkeys);
    
    free(results);
    free(cb.ret);
    free(keys);
    free(nkeys);

    return enif_make_tuple2(env, A_OK(env), returnValue);
}

ERL_NIF_TERM return_lcb_error(ErlNifEnv* env, int const value) {
    switch (value) {
        case LCB_SUCCESS:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "success"));
        case LCB_AUTH_CONTINUE:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "auth_continue"));
        case LCB_AUTH_ERROR:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "auth_error"));
        case LCB_DELTA_BADVAL:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "delta_badval"));
        case LCB_E2BIG:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "e2big"));
        case LCB_EBUSY:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "ebusy"));
        case LCB_EINTERNAL:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "einternal"));
        case LCB_EINVAL:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "einval"));
        case LCB_ENOMEM:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "enomem"));
        case LCB_ERANGE:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "erange"));
        case LCB_ERROR:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "error"));
        case LCB_ETMPFAIL:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "etmpfail"));
        case LCB_KEY_EEXISTS:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "key_eexists"));
        case LCB_KEY_ENOENT:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "key_enoent"));
        case LCB_NETWORK_ERROR:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "network_error"));
        case LCB_NOT_MY_VBUCKET:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "not_my_vbucket"));
        case LCB_NOT_STORED:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "not_stored"));
        case LCB_NOT_SUPPORTED:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "not_supported"));
        case LCB_UNKNOWN_COMMAND:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "unknown_command"));
        case LCB_UNKNOWN_HOST:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "unknown_host"));
        case LCB_PROTOCOL_ERROR:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "protocol_error"));
        case LCB_ETIMEDOUT:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "etimedout"));
        case LCB_CONNECT_ERROR:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "connect_error"));
        case LCB_BUCKET_ENOENT:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "bucket_enoent"));
        case LCB_CLIENT_ENOMEM:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "client_enomem"));
        default:
            return enif_make_tuple2(env, A_ERROR(env), enif_make_atom(env, "unknown_error"));            
    }
}

ERL_NIF_TERM return_value(ErlNifEnv* env, void * cookie) {
    struct libaerospike_callback *cb;
    cb = (struct libaerospike_callback *)cookie;
    ErlNifBinary value_binary;
    ERL_NIF_TERM term;
    enif_alloc_binary(cb->size, &value_binary);
    memcpy(value_binary.data, cb->data, cb->size);
    term  =   enif_make_tuple3(env, enif_make_int(env, cb->cas),
                                           enif_make_int(env, cb->flag), 
                                           enif_make_binary(env, &value_binary));
    free(cb->data);
    return term;
}
