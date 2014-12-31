#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "as_key.h"
#include <aerospike/as_arraylist_iterator.h>

void* as_key_remove_args(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    DEBUG_TRACE("begin args");

    key_remove_args_t* args = (key_remove_args_t*)enif_alloc(sizeof(key_remove_args_t));

    // ns, set, key
    if (!init_key_from_args(env, &args->key, argv)) goto error0;

    // timeout
    if (!init_policy_apply_from_arg(env, &args->policy, argv[3])) goto error1;

    DEBUG_TRACE("end args");

    return args;

    error1:
    as_key_destroy(&args->key);
    error0:
    enif_free(args);

    return NULL;
}

ERL_NIF_TERM as_key_remove(ErlNifEnv* env, handle_t* handle, void* obj)
{
    DEBUG_TRACE("begin");

    key_remove_args_t* args = (key_remove_args_t *)obj;

    as_status res;
	as_error err;

	// Add an integer value to the set.
    res = aerospike_key_remove(&handle->instance, &err, &args->policy, &args->key);

    DEBUG_TRACE("end res: %d", res);

    if(res != AEROSPIKE_OK)
        return A_AS_ERROR(env, err);

    return A_OK(env);
}
