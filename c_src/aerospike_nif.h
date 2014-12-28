#ifndef CBERL_NIF_H
#define CBERL_NIF_H

#include "erl_nif.h"
#include "aerospike.h"

// Command enum
#define CMD_CONNECT     0
#define LSET_ADD        8
#define LSET_REMOVE     9
#define LSET_GET        10
#define LSET_SIZE       11


typedef struct task {
    ErlNifPid* pid;
    unsigned int cmd;
    void *args;
} task_t;

static void* worker(void *obj);

#endif
