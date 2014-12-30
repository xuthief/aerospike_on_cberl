#ifndef ASERL_NIF_H
#define ASERL_NIF_H

#include "erl_nif.h"

// Command enum
#define CMD_CONNECT         0
#define CMD_LSET_ADD        8
#define CMD_LSET_REMOVE     9
#define CMD_LSET_GET        10
#define CMD_LSET_SIZE       11
#define CMD_MAX             (CMD_LSET_SIZE+1)

typedef struct task {
    ErlNifPid* pid;
    unsigned int cmd;
    void *args;
} task_t;

static void* worker(void *obj);

#endif
