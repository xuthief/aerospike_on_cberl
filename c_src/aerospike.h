#ifndef ASERL_H
#define ASERL_H

#include <aerospike/aerospike.h>
#include "queue.h"
#include "aserl_nif.h"
#include "aserl_error.h"

#define A_OK(env)                   enif_make_atom(env, "ok")
#define A_OK_VALUE(env, val)        enif_make_tuple2(env, A_OK(env), val)
#define A_ERROR(env)                enif_make_atom(env, "error")
#define A_AS_ERROR(env, err)        enif_make_tuple2(env, A_ERROR(env), enif_make_tuple2(env, enif_make_atom(env, aserl_error_status_string(err.code)), enif_make_string(env, err.message, ERL_NIF_LATIN1)))

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
