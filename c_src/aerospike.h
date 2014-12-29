#ifndef ASERL_H
#define ASERL_H

#include <aerospike/aerospike.h>
#include "queue.h"
#include "aerospike_nif.h"

#define A_OK(env)            enif_make_atom(env, "ok")
#define A_ERROR(env)    enif_make_atom(env, "error")

#define NIF(name)  ERL_NIF_TERM name(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])

#define assert_badarg(S, Env) if (! S) { return enif_make_badarg(env); }

typedef struct handle {
    ErlNifTid thread;
    ErlNifThreadOpts* thread_opts;
    queue_t *queue;
    ERL_NIF_TERM (*calltable[CMD_MAX])(ErlNifEnv* env, struct handle* handle, void* obj);
    void* (*args_calltable[CMD_MAX])(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    aerospike instance;
} handle_t;

#endif
