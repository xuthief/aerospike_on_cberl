#include <string.h>
#include <stdio.h>
#include "aerospike_nif.h"
#include "as.h"

static ErlNifResourceType* aerospike_handle = NULL;

static void aerospike_handle_cleanup(ErlNifEnv* env, void* arg) {}

static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
{
    ErlNifResourceFlags flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
    aerospike_handle =  enif_open_resource_type(env, "aerospike_nif",
                                                 "aerospike_handle",
                                                 &aerospike_handle_cleanup,
                                                 flags, 0);
    return 0;
}

NIF(aerospike_nif_new)
{
    handle_t* handle = enif_alloc_resource(aerospike_handle, sizeof(handle_t));
    handle->queue = queue_new();

    handle->calltable[CMD_CONNECT]         = as_connect;
    handle->args_calltable[CMD_CONNECT]    = as_connect_args;
    handle->calltable[LSET_ADD]            = as_ldt_store;
    handle->args_calltable[LSET_ADD]       = as_ldt_store_args;
    handle->calltable[LSET_REMOVE]         = as_ldt_store;
    handle->args_calltable[LSET_REMOVE]    = as_ldt_store_args;
    handle->calltable[LSET_GET]            = as_ldt_get;
    handle->args_calltable[LSET_GET]       = as_ldt_get_args;
    handle->calltable[LSET_SIZE]           = as_ldt_get;
    handle->args_calltable[LSET_SIZE]      = as_ldt_get_args;

    handle->thread_opts = enif_thread_opts_create("thread_opts");

    if (enif_thread_create("", &handle->thread, worker, handle, handle->thread_opts) != 0) {
        return enif_make_atom(env, "error");
    }

    return enif_make_tuple2(env, enif_make_atom(env, "ok"), enif_make_resource(env, handle));
}

NIF(aerospike_nif_control)
{
    handle_t* handle;

    assert_badarg(enif_get_resource(env, argv[0], aerospike_handle, (void **) &handle), env);

    unsigned int len;
    enif_get_atom_length(env, argv[1], &len, ERL_NIF_LATIN1);
    int cmd;
    enif_get_int(env, argv[1], &cmd);

    if (cmd == -1) {
        return enif_make_badarg(env);
    }

    ErlNifPid* pid = (ErlNifPid*)enif_alloc(sizeof(ErlNifPid));
    task_t* task = (task_t*)enif_alloc(sizeof(task_t));

    unsigned arg_length;
    if (!enif_get_list_length(env, argv[2], &arg_length)) {
        enif_free(pid);
        enif_free(task);
        return enif_make_badarg(env);
    }

    ERL_NIF_TERM nargs = argv[2];
    ERL_NIF_TERM head, tail;
    ERL_NIF_TERM* new_argv = (ERL_NIF_TERM*)enif_alloc(sizeof(ERL_NIF_TERM) * arg_length);
    int i = 0;
    while (enif_get_list_cell(env, nargs, &head, &tail)) {
        new_argv[i] = head;
        i++;
        nargs = tail;
    }

    void* args = handle->args_calltable[cmd](env, argc, new_argv);

    enif_free(new_argv);

    if(args == NULL) {
        enif_free(pid);
        enif_free(task);
        return enif_make_badarg(env);
    }

    enif_self(env, pid);

    task->pid  = pid;
    task->cmd  = cmd;
    task->args = args;

    queue_put(handle->queue, task);

    return A_OK(env);
}

NIF(aerospike_nif_destroy) {
    handle_t * handle;
    void* resp;
    assert_badarg(enif_get_resource(env, argv[0], aerospike_handle, (void **) &handle), env);      
    queue_put(handle->queue, NULL); // push NULL into our queue so the thread will join
    enif_thread_join(handle->thread, &resp);
    queue_destroy(handle->queue);
    enif_thread_opts_destroy(handle->thread_opts);

	as_error err;
	// Disconnect from the database cluster and clean up the aerospike object.
	aerospike_close(&handle->instance, &err);
    aerospike_destroy(&handle->instance);

    enif_release_resource(handle); 
    return A_OK(env);
}

static void* worker(void *obj)
{
    handle_t* handle = (handle_t*)obj;

    task_t* task;
    ErlNifEnv* env = enif_alloc_env();

    while ((task = (task_t*)queue_get(handle->queue)) != NULL) {
        ERL_NIF_TERM result = handle->calltable[task->cmd](env, handle, task->args);
        enif_send(NULL, task->pid, env, result);
        enif_free(task->pid);
        enif_free(task->args);
        enif_free(task);
        enif_clear_env(env);
    }

    return NULL;
}

static ErlNifFunc nif_funcs[] = {
    {"new", 0, aerospike_nif_new},
    {"control", 3, aerospike_nif_control},
    {"destroy", 1, aerospike_nif_destroy}
};

ERL_NIF_INIT(aerospike_nif, nif_funcs, load, NULL, NULL, NULL);
