-define('CBE_ADD',      1).
-define('CBE_REPLACE',  2).
-define('CBE_SET',      3).
-define('CBE_APPEND',   4).
-define('CBE_PREPEND',  5).
%% /** For queue ops */
-define('CBE_LENQUEUE', 16#0007).
-define('CBE_LREMOVE',  16#0008).

-define('CMD_CONNECT',    0).
-define('CMD_STORE',      1).
-define('CMD_MGET',       2).
-define('CMD_UNLOCK',     3).
-define('CMD_MTOUCH',     4).
-define('CMD_ARITHMETIC', 5).
-define('CMD_REMOVE',     6).
-define('CMD_HTTP',       7).
%% /** FOR lset ops */
-define('LSET_ADD',     8).
-define('LSET_REMOVE',  9).
-define('LSET_GET',     10).
-define('LSET_SIZE',    11).

%% for get types
-define('CBE_GET',          16#0000).
-define('CBE_LGET',         16#0001).
-define('CBE_LDEQUEUE',     16#0002).
-define('CBE_SGET',         16#0003).

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
-type operation_type() :: add | replace | set | append | prepend | lenqueue | lremove | sadd | sremove | sismember.
-type instance() :: #instance{}.
-type http_type() :: view | management | raw.
-type http_method() :: get | post | put | delete.
