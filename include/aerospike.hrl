-define('CMD_CONNECT',    0).
-define('CMD_LSET_ADD',      8).
-define('CMD_LSET_REMOVE',   9).
-define('CMD_LSET_GET',      10).
-define('CMD_LSET_SIZE',     11).

-type handle() :: binary().

-record(instance, {handle :: handle(),
                   bucketname :: string(),
                   transcoder :: module()}).

-type key() :: string().
-type value() :: string() | list() | integer() | binary().
-type ns() :: string().
-type set() :: string().
-type ldt() :: string().
-type timeout() :: integer().
-type instance() :: #instance{}.
