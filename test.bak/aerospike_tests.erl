-module(aerospike_tests).
-include_lib("eunit/include/eunit.hrl").
-define(POOLNAME, testpool).

aerospike_test_() ->
    [{foreach, fun setup/0, fun clean_up/1,
      [
       fun test_set_and_get/1
       ,fun test_replace_add/1
       ,fun test_get_and_touch/1
       ,fun test_append_prepend/1
       ,fun test_remove/1
       ,fun test_lock/1
%      ,fun test_flush/1
%       fun test_flush_1/1
      ]}].


%%%===================================================================
%%% Setup / Teardown
%%%===================================================================

setup() ->
    aerospike:start_link(?POOLNAME, 3),
    ok.

clean_up(_) ->
    aerospike:remove(?POOLNAME, <<"testkey">>),
    aerospike:remove(?POOLNAME, <<"testkey1">>),
    aerospike:remove(?POOLNAME, <<"notestkey">>),
    aerospike:stop(?POOLNAME).

%%%===================================================================
%%% Tests
%%%===================================================================

test_set_and_get(_) ->
    Key = <<"testkey">>,
    Value = "testval",
    ok = aerospike:set(?POOLNAME, Key, 0, Value),
    Get1 = aerospike:get(?POOLNAME, Key),
    ok = aerospike:set(?POOLNAME, Key, 0, Value, json),
    Get2 = aerospike:get(?POOLNAME, Key),
    %ok = aerospike:set(?POOLNAME, Key, 0, Value, raw_binary),
    %Get3 = aerospike:get(?POOLNAME, Key),
    [?_assertMatch({Key, _, Value}, Get1),
     ?_assertMatch({Key, _, Value}, Get2)
     %,?_assertMatch({Key, _, Value}, Get3)
    ].

test_replace_add(_) ->
    Key = <<"testkey">>,
    Value = "testval",
    ok = aerospike:set(?POOLNAME, Key, 0, Value),
    AddFail = aerospike:add(?POOLNAME, Key, 0, Value),
    AddPass = aerospike:add(?POOLNAME, <<"testkey1">>, 0, Value),
    ReplaceFail = aerospike:replace(?POOLNAME, <<"notestkey">>, 0, Value),
    ok = aerospike:replace(?POOLNAME, Key, 0, "testval1"),
    Get1 = aerospike:get(?POOLNAME, Key),
    [?_assertEqual({error, key_eexists}, AddFail),
     ?_assertEqual(ok, AddPass),
     ?_assertEqual({error, key_enoent}, ReplaceFail),
     ?_assertMatch({Key, _, "testval1"}, Get1)
    ].

test_append_prepend(_) ->
    Key = <<"testkey">>,
    ok = aerospike:set(?POOLNAME, Key, 0, "base", str),
    ok = aerospike:append(?POOLNAME, 0, Key, "tail"),
    Get1 = aerospike:get(?POOLNAME, Key),
    ok = aerospike:prepend(?POOLNAME, 0, Key, "head"),
    Get2 = aerospike:get(?POOLNAME, Key),
    [?_assertMatch({Key, _, "basetail"}, Get1),
     ?_assertMatch({Key, _, "headbasetail"}, Get2)
    ].

test_get_and_touch(_) ->
    Key = <<"testkey">>,
    Value = "testval",
    ok = aerospike:set(?POOLNAME, Key, 0, Value),
    aerospike:get_and_touch(?POOLNAME, Key, 1),
    timer:sleep(5000),
    [?_assertEqual({Key, {error,key_enoent}}, aerospike:get(?POOLNAME, Key))].

test_remove(_) ->
    Key = <<"testkey">>,
    Value = "testval",
    ok = aerospike:set(?POOLNAME, Key, 0, Value),
    ok = aerospike:remove(?POOLNAME, Key),
    [?_assertEqual({Key, {error,key_enoent}}, aerospike:get(?POOLNAME, Key))].

test_lock(_) ->
    Key = <<"testkey">>,
    Value = "testval",
    Value2 = "testval2",
    ok = aerospike:set(?POOLNAME, Key, 0, Value),
    {Key, CAS, _Exp} = aerospike:get_and_lock(?POOLNAME, Key, 100000),
    fun () ->
        [?assertEqual({error,key_eexists}, aerospike:set(?POOLNAME, Key, 0, Value2)),
         ?assertEqual(ok, aerospike:unlock(?POOLNAME, Key, CAS)),
         ?assertEqual(ok, aerospike:set(?POOLNAME, Key, 0, Value2))]
    end.

%test_flush(_) ->
%    Key = <<"testkey">>,
%    Value = "testval",
%    ok = aerospike:set(?POOLNAME, Key, 0, Value),
%    fun() ->
%        [?assertMatch(ok, aerospike:flush(?POOLNAME, "default")),
%         ?assertMatch({Key, {error, key_enoent}}, aerospike:get(?POOLNAME, Key))]
%    end.
%
%test_flush_1(_) ->
%    Key = <<"testkey">>,
%    Value = "testval",
%    ok = aerospike:set(?POOLNAME, Key, 0, Value),
%    fun() ->
%        [?assertMatch(ok, aerospike:flush(?POOLNAME)),
%         ?assertMatch({Key, {error, key_enoent}}, aerospike:get(?POOLNAME, Key))]
%    end.
%
