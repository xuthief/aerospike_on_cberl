%%% @author Ali Yakamercan <aliyakamercan@gmail.com>
%%% @copyright 2012-2013 Chitika Inc.
%%% @version 0.0.2

-module(aserl).
-include("aserl.hrl").

-export([start_link/1, start_link/2, start_link/4, start_link/6]).
-export([stop/1]).
%store operations
-export([add/4, add/5, replace/4, replace/5, set/4, set/5, store/7]).
%update operations
-export([append/4, prepend/4, touch/3, mtouch/3]).
-export([incr/3, incr/4, incr/5, decr/3, decr/4, decr/5]).
-export([arithmetic/6]).
%retrieval operations
-export([get_and_touch/3, get_and_lock/3, mget/2, mget/4, get/2, get/3, unlock/3,
         mget/3, getl/3, http/6, view/4, foldl/3, foldr/3, foreach/2]).
%remove
-export([remove/5, remove/4]).
%design doc opertations
-export([set_design_doc/3, remove_design_doc/2]).
%queue opts
-export([lenqueue/4, ldequeue/3, lremove/4, lget/2]).
%sets opts
-export([lset_add/7, lset_remove/7, lset_get/6, lset_size/6]).
-export([lset_add/6, lset_remove/6, lset_get/5, lset_size/5]).

%% @doc Create an instance of libaerospike
%% PoolName The aerospike connection pool to use
%% NumCon The aerospike connection pool count
%% Host (ex: "127.0.0.1" etc).
%% Port (ex: 3000).
%% Username The username to use
%% Password The password
%%
%% @equiv start_link(PoolName, NumCon, Host, Username, Password).
start_link(PoolName) ->
    start_link(PoolName, 1).
start_link(PoolName, NumCon) ->
    start_link(PoolName, NumCon, "localhost", 3000).
start_link(PoolName, NumCon, Host, Port) ->
    start_link(PoolName, NumCon, Host, Port, "", "").
-spec start_link(atom(), integer(), string(), integer(), string(), string()) -> {ok, pid()} | {error, _}.
start_link(PoolName, NumCon, Host, Port, Username, Password) ->
    SizeArgs = [{size, NumCon},
                {max_overflow, 0}],
    PoolArgs = [{name, {local, PoolName}},
                {worker_module, aserl_worker}] ++ SizeArgs,
    WorkerArgs = [{host, Host},
		  {port, Port},
		  {username, Username},
		  {password, Password}],
    poolboy:start_link(PoolArgs, WorkerArgs).

%%%%%%%%%%%%%%%%%%%%%%%%
%%% STORE OPERATIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%

%% @equiv add(PoolPid, Key, Exp, Value, standard)
-spec add(pid(), key(), integer(), value()) -> ok | {error, _}.
add(PoolPid, Key, Exp, Value) ->
    add(PoolPid, Key, Exp, Value, standard).

%% @equiv store(PoolPid, add, Key, Value, TranscoderOpts, Exp, 0)
-spec add(pid(), key(), integer(), value(), atom()) -> ok | {error, _}.
add(PoolPid, Key, Exp, Value, TranscoderOpts) ->
    store(PoolPid, add, Key, Value, TranscoderOpts, Exp, 0).

%% @equiv replace(PoolPid, Key, Exp, Value, standard)
-spec replace(pid(), key(), integer(), value()) -> ok | {error, _}.
replace(PoolPid, Key, Exp, Value) ->
    replace(PoolPid, Key, Exp, Value, standard).

%% @equiv store(PoolPid, replace, "", Key, Value, Exp)
-spec replace(pid(), key(), integer(), value(), atom()) -> ok | {error, _}.
replace(PoolPid, Key, Exp, Value, TranscoderOpts) ->
    store(PoolPid, replace, Key, Value, TranscoderOpts, Exp, 0).

%% @equiv set(PoolPid, Key, Exp, Value, standard)
-spec set(pid(), key(), integer(), value()) -> ok | {error, _}.
set(PoolPid, Key, Exp, Value) ->
    set(PoolPid, Key, Exp, Value, standard).

%% @equiv store(PoolPid, set, "", Key, Value, Exp)
-spec set(pid(), key(), integer(), value(), atom()) -> ok | {error, _}.
set(PoolPid, Key, Exp, Value, TranscoderOpts) ->
    store(PoolPid, set, Key, Value, TranscoderOpts, Exp, 0).

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% UPDATE OPERATIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

-spec append(pid(), integer(), key(), value()) -> ok | {error, _}.
append(PoolPid, Cas, Key, Value) ->
    store(PoolPid, append, Key, Value, str, 0, Cas).

-spec prepend(pid(), integer(), key(), value()) -> ok | {error, _}.
prepend(PoolPid, Cas, Key, Value) ->
    store(PoolPid, prepend, Key, Value, str, 0, Cas).

%% @doc Touch (set expiration time) on the given key
%% PoolPid libaserl instance to use
%% Key key to touch
%% ExpTime a new expiration time for the item

-spec touch(pid(), key(), integer()) -> {ok, any()}.
touch(PoolPid, Key, ExpTime) ->
    {ok, Return} = mtouch(PoolPid, [Key], [ExpTime]),
    {ok, hd(Return)}.

-spec mtouch(pid(), [key()], integer() | [integer()])
	    -> {ok, any()} | {error, any()}.
mtouch(PoolPid, Keys, ExpTime) when is_integer(ExpTime) ->
    mtouch(PoolPid, Keys, [ExpTime]);
mtouch(PoolPid, Keys, ExpTimes) ->
    ExpTimesE = case length(Keys) - length(ExpTimes) of
        R when R > 0 ->
            ExpTimes ++ lists:duplicate(R, lists:last(ExpTimes));
        _ ->
            ExpTimes
    end,
    execute(PoolPid, {mtouch, Keys, ExpTimesE}).

incr(PoolPid, Key, OffSet) ->
    arithmetic(PoolPid, Key, OffSet, 0, 0, 0).

incr(PoolPid, Key, OffSet, Default) ->
    arithmetic(PoolPid, Key, OffSet, 0, 1, Default).

incr(PoolPid, Key, OffSet, Default, Exp) ->
    arithmetic(PoolPid, Key, OffSet, Exp, 1, Default).

decr(PoolPid, Key, OffSet) ->
    arithmetic(PoolPid, Key, -OffSet, 0, 0, 0).

decr(PoolPid, Key, OffSet, Default) ->
    arithmetic(PoolPid, Key, -OffSet, 0, 1, Default).

decr(PoolPid, Key, OffSet, Default, Exp) ->
    arithmetic(PoolPid, Key, -OffSet, Exp, 1, Default).

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% RETRIEVAL METHODS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

-spec get_and_touch(pid(), key(), integer()) -> [{ok, integer(), value()} | {error, _}].
get_and_touch(PoolPid, Key, Exp) ->
    mget(PoolPid, [Key], Exp).

-spec get(pid(), key(), atom()) -> {ok, integer(), value()} | {error, _}.
get(PoolPid, Key, TranscoderOpts) ->
    hd(mget(PoolPid, [Key], 0, {trans, TranscoderOpts})).

-spec get(pid(), key()) -> {ok, integer(), value()} | {error, _}.
get(PoolPid, Key) ->
    hd(mget(PoolPid, [Key], 0)).

mget(PoolPid, Keys) ->
    mget(PoolPid, Keys, 0).

-spec get_and_lock(pid(), key(), integer()) -> {ok, integer(), value()} | {error, _}.
get_and_lock(PoolPid, Key, Exp) ->
    hd(getl(PoolPid, Key, Exp)).

-spec unlock(pid(), key(), integer()) -> ok | {error, _}.
unlock(PoolPid, Key, Cas) ->
    execute(PoolPid, {unlock, Key, Cas}).

%% @doc main store function takes care of all storing
%% Instance libaserl instance to use
%% Op add | replace | set | append | prepend
%%          add : Add the item to the cache, but fail if the object exists already
%%          replace: Replace the existing object in the cache
%%          set : Unconditionally set the object in the cache
%%          append/prepend : Append/Prepend this object to the existing object
%% Key the key to set
%% Value the value to set
%% Transcoder to encode the value
%% Exp When the object should expire. The expiration time is
%%     either an offset into the future.. OR an absolute
%%     timestamp, depending on how large (numerically) the
%%     expiration is. if the expiration exceeds 30 days
%%     (i.e. 24 * 3600 * 30) then it's an absolute timestamp.
%%     pass 0 for infinity
%% CAS
-spec store(pid(), atom(), key(), value(), atom(),
            integer(), integer()) -> ok | {error, _}.
store(PoolPid, Op, Key, Value, TranscoderOpts, Exp, Cas) ->
    execute(PoolPid, {store, Op, Key, Value,
                       TranscoderOpts, Exp, Cas}).

%% @doc get the value for the given key
%% Instance libaserl instance to use
%% HashKey the key to use for hashing
%% Key the key to get
%% Exp When the object should expire
%%      pass a negative number for infinity
-spec mget(pid(), [key()], integer()) -> list().
mget(PoolPid, Keys, Exp) ->
    execute(PoolPid, {mget, Keys, Exp, 0}).

mget(PoolPid, Keys, Exp, {trans, TranscoderOpts}) ->
    execute(PoolPid, {mget, Keys, Exp, 0, {trans, aserl_transcoder:flag(TranscoderOpts)}});

mget(PoolPid, Keys, Exp, Type) ->
    execute(PoolPid, {mget, Keys, Exp, 0, Type}).

%% @doc Get an item with a lock that has a timeout
%% Instance libaserl instance to use
%%  HashKey the key to use for hashing
%%  Key the key to get
%%  Exp When the lock should expire
-spec getl(pid(), key(), integer()) -> list().
getl(PoolPid, Key, Exp) ->
    execute(PoolPid, {mget, [Key], Exp, 1}).

%% @doc perform an arithmetic operation on the given key
%% Instance libaserl instance to use
%% Key key to perform on
%% Delta The amount to add / subtract
%% Exp When the object should expire
%% Create set to true if you want the object to be created if it
%%        doesn't exist.
%% Initial The initial value of the object if we create it
-spec arithmetic(pid(), key(), integer(), integer(), integer(), integer()) ->
   ok | {error, _}.
arithmetic(PoolPid, Key, OffSet, Exp, Create, Initial) ->
    execute(PoolPid, {arithmetic, Key, OffSet, Exp, Create, Initial}).

%% @doc remove the value for given key
%% Instance libaserl instance to use
%% Key key to  remove
%% @equiv remove(PoolPid, NS, Set, Key, Timeout)
-spec remove(pid(), ns(), set(), key(), timeout()) -> ok | {error, _}.
remove(PoolPid, NS, Set, Key, Timeout) ->
    ?trace("remove ~p", [Key]),
    execute(PoolPid, {key_remove, NS, Set, Key, Timeout}).
remove(PoolPid, NS, Set, Key) ->
    remove(PoolPid, NS, Set, Key, 0).

%% @doc execute a command with the REST API
%% PoolPid pid of connection pool
%% Path HTTP path
%% Body HTTP body (for POST requests)
%% ContentType HTTP content type
%% Method HTTP method
%% Type Couchbase request type
-spec http(pid(), string(), string(), string(), atom(), atom())
	  -> {ok, binary()} | {error, _}.
http(PoolPid, Path, Body, ContentType, Method, Type) ->
    execute(PoolPid, {http, Path, Body, ContentType, http_method(Method), http_type(Type)}).

%% @doc Query a view
%% PoolPid pid of connection pool
%% DocName design doc name
%% ViewName view name
%% Args arguments and filters (limit etc.)
view(PoolPid, DocName, ViewName, Args) ->
    Path = string:join(["_design", DocName, "_view", ViewName], "/"),
    Resp = case proplists:get_value(keys, Args) of
        undefined ->  %% FIXME maybe not have to pass in an empty json obj here
            http(PoolPid, string:join([Path, query_args(Args)], "?"), "{}", "application/json", get, view);
        Keys ->
            http(PoolPid, string:join([Path, query_args(proplists:delete(keys, Args))], "?"), binary_to_list(jiffy:encode({[{keys, Keys}]})), "application/json", post, view)
    end,
    decode_query_resp(Resp).

foldl(Func, Acc, {PoolPid, DocName, ViewName, Args}) ->
    case view(PoolPid, DocName, ViewName, Args) of
        {ok, {_TotalRows, Rows}} ->
            lists:foldl(Func, Acc, Rows);
        {error, _} = E -> E
    end.

foldr(Func, Acc, {PoolPid, DocName, ViewName, Args}) ->
    case view(PoolPid, DocName, ViewName, Args) of
        {ok, {_TotalRows, Rows}} ->
            lists:foldr(Func, Acc, Rows);
        {error, _} = E -> E
    end.

foreach(Func, {PoolPid, DocName, ViewName, Args}) ->
    case view(PoolPid, DocName, ViewName, Args) of
        {ok, {_TotalRows, Rows}} ->
            lists:foreach(Func, Rows);
        {error, _} = E -> E
    end.

stop(PoolPid) ->
    poolboy:stop(PoolPid).

execute(PoolPid, Cmd) ->
    poolboy:transaction(PoolPid, fun(Worker) ->
            gen_server:call(Worker, Cmd, infinity)
       end, infinity).

http_type(view) -> 0;
http_type(management) -> 1;
http_type(raw) -> 2.

http_method(get) -> 0;
http_method(post) -> 1;
http_method(put) -> 2;
http_method(delete) -> 3.

query_args(Args) when is_list(Args) ->
    string:join([query_arg(A) || A <- Args], "&").

decode_query_resp({ok, _, Resp}) ->
    case jiffy:decode(Resp) of
        {[{<<"total_rows">>, TotalRows}, {<<"rows">>, Rows}]} ->
            {ok, {TotalRows, lists:map(fun ({Row}) -> Row end, Rows)}};
        {[{<<"rows">>, Rows}]} ->
            {ok, {lists:map(fun ({Row}) -> Row end, Rows)}};
        {[{<<"error">>,Error}, {<<"reason">>, Reason}]} ->
            {error, {view_error(Error), Reason}}
    end;
decode_query_resp({error, _} = E) -> E.

query_arg({descending, true}) -> "descending=true";
query_arg({descending, false}) -> "descending=false";

query_arg({endkey, V}) when is_list(V) -> string:join(["endkey", V], "=");

query_arg({endkey_docid, V}) when is_list(V) -> string:join(["endkey_docid", V], "=");

query_arg({full_set, true}) -> "full_set=true";
query_arg({full_set, false}) -> "full_set=false";

query_arg({group, true}) -> "group=true";
query_arg({group, false}) -> "group=false";

query_arg({group_level, V}) when is_integer(V) -> string:join(["group_level", integer_to_list(V)], "=");

query_arg({inclusive_end, true}) -> "inclusive_end=true";
query_arg({inclusive_end, false}) -> "inclusive_end=false";

query_arg({key, V}) when is_binary(V) -> string:join(["key", binary_to_list(jiffy:encode(V))], "=");

query_arg({keys, V}) when is_list(V) -> string:join(["keys", jiffy:encode(V)], "=");

query_arg({limit, V}) when is_integer(V) -> string:join(["limit", integer_to_list(V)], "=");

query_arg({on_error, continue}) -> "on_error=continue";
query_arg({on_error, stop}) -> "on_error=stop";

query_arg({reduce, true}) -> "reduce=true";
query_arg({reduce, false}) -> "reduce=false";

query_arg({skip, V}) when is_integer(V) -> string:join(["skip", integer_to_list(V)], "=");

query_arg({stale, false}) -> "stale=false";
query_arg({stale, ok}) -> "stale=ok";
query_arg({stale, update_after}) -> "stale=update_after";

query_arg({startkey, V}) when is_list(V) -> string:join(["startkey", V], "=");

query_arg({startkey_docid, V}) when is_list(V) -> string:join(["startkey_docid", V], "=").

view_error(<<"not_found">>) -> not_found;
view_error(<<"bad_request">>) -> bad_request;
view_error(<<"req_timedout">>) -> req_timedout;
view_error(Error) -> list_to_atom(binary_to_list(Error)). %% kludge until I figure out all the errors

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DESIGN DOCUMENT MANAGMENT %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_design_doc(PoolPid, DocName, DesignDoc) ->
    Path = string:join(["_design", DocName], "/"),
    {ok, _, _} = http(PoolPid, Path, binary_to_list(jiffy:encode(DesignDoc)), "application/json", put, view),
    ok.

remove_design_doc(PoolPid, DocName) ->
    Path = string:join(["_design", DocName], "/"),
    {ok, _, _} = http(PoolPid, Path, "", "application/json", delete, view),
    ok.


%%%%%%%%%%%%%%%%%%%%%%%%
%%% QUEUE OPERATIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%

%% @equiv lenqueue(PoolPid, Key, Exp, Value, standard)
-spec lenqueue(pid(), key(), integer(), integer()) -> ok | {error, _}.
lenqueue(PoolPid, Key, Exp, Value) ->
    BinValue = <<Value:64/unsigned-integer>>,
    store(PoolPid, lenqueue, Key, BinValue, transparent, Exp, 0).

%% @equiv lremove(PoolPid, Key, Exp, Value, standard)
-spec lremove(pid(), key(), integer(), integer()) -> ok | {error, _}.
lremove(PoolPid, Key, Exp, Value) ->
    BinValue = <<Value:64/unsigned-integer>>,
    store(PoolPid, lremove, Key, BinValue, transparent, Exp, 0).

%% @equiv ldequeue(PoolPid, Key, Exp, standard)
-spec ldequeue(pid(), key(), integer()) -> ok | {error, _}.
ldequeue(PoolPid, Key, Exp) ->
    hd(mget(PoolPid, [Key], Exp, 0)).

%% @equiv lget(PoolPid, Key)
-spec lget(pid(), key()) -> ok | {error, _}.
lget(PoolPid, Key) ->
    hd(mget(PoolPid, [Key], 0, 0)).

%%%%%%%%%%%%%%%%%%%%%%%%
%%% SETS OPERATIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%

%% @equiv lset_add(PoolPid, NS, Set, Key, Ldt, Value, Timeout)
-spec lset_add(pid(), ns(), set(), key(), ldt(), value(), timeout()) -> ok | {error, _}.
lset_add(PoolPid, NS, Set, Key, Ldt, Value, Timeout) ->
    execute(PoolPid, {lset_store, lset_add, NS, Set, Key, Ldt, Timeout, 
                      Value
                      }).
lset_add(PoolPid, NS, Set, Key, Ldt, Value) ->
    lset_add(PoolPid, NS, Set, Key, Ldt, Value, 0).

%% @equiv lset_remove(PoolPid, NS, Set, Key, Ldt, Value, Timeout)
-spec lset_remove(pid(), ns(), set(), key(), ldt(), value(), timeout()) -> ok | {error, _}.
lset_remove(PoolPid, NS, Set, Key, Ldt, Value, Timeout) ->
    execute(PoolPid, {lset_store, lset_remove, NS, Set, Key, Ldt, Timeout,
                      Value
                      }).
lset_remove(PoolPid, NS, Set, Key, Ldt, Value) ->
    lset_remove(PoolPid, NS, Set, Key, Ldt, Value, 0).

%% @equiv lset_get(PoolPid, NS, Set, Key, Ldt, Timeout)
-spec lset_get(pid(), ns(), set(), key(), ldt(), timeout()) -> ok | {error, _}.
lset_get(PoolPid, NS, Set, Key, Ldt, Timeout) ->
    execute(PoolPid, {lset_get, lset_get, NS, Set, Key, Ldt, 
                      Timeout}).

lset_get(PoolPid, NS, Set, Key, Ldt) ->
    lset_get(PoolPid, NS, Set, Key, Ldt, 0).

%% @equiv lset_size(PoolPid, NS, Set, Key, Ldt, Timeout)
-spec lset_size(pid(), ns(), set(), key(), ldt(), timeout()) -> ok | {error, _}.
lset_size(PoolPid, NS, Set, Key, Ldt, Timeout) ->
    execute(PoolPid, {lset_get, lset_size, NS, Set, Key, Ldt, 
                      Timeout}).

lset_size(PoolPid, NS, Set, Key, Ldt) ->
    lset_size(PoolPid, NS, Set, Key, Ldt, 0).
