-module(aerospike_sets_tests).
-include_lib("eunit/include/eunit.hrl").
-define(POOLNAME, testpool).

aerospike_test_() ->
    [{foreach, fun setup/0, fun clean_up/1,
      [
                fun test_sadd/1
                ,fun test_size/1
                ,fun test_sremove/1
                ]}].


%%%===================================================================
%%% Setup / Teardown
%%%===================================================================

setup() ->
    aerospike:start_link(?POOLNAME, 1, "10.37.129.7", 3000, "", ""),
    %aerospike:remove(?POOLNAME, <<"testkey">>),
    %aerospike:remove(?POOLNAME, <<"testkey1">>),
    %aerospike:remove(?POOLNAME, <<"testkey2">>),
    ok.

clean_up(_) ->
    aerospike:stop(?POOLNAME).

%%%===================================================================
%%% Tests
%%%===================================================================

test_sadd(_) ->
    Ns = "test",
    Set = "test-set",
    Key = "test-key",
    Key2 = <<"testkey2">>,
    Value = 1000,
    Ldt = "mylset",
    aerospike:lset_add(?POOLNAME, Ns, Set, Key, Ldt, Value, 1000),
    Get1 = aerospike:lset_get(?POOLNAME, Ns, Set, Key, Ldt, 100),
    aerospike:lset_add(?POOLNAME, Ns, Set, Key, Ldt, Value, 0),
    Get2 = aerospike:lset_get(?POOLNAME, Ns, Set, Key, Ldt, 0),
    Value2 = 2,
    aerospike:lset_add(?POOLNAME, Ns, Set, Key, Ldt, Value2),
    Get3 = aerospike:lset_get(?POOLNAME, Ns, Set, Key, Ldt),
    GetFail = aerospike:lset_get(?POOLNAME, Ns, Set, Key2, Ldt),
    [?_assertMatch({ok, [Value]}, Get1)
     ,?_assertMatch({Key, _, [Value]}, Get2)
     ,?_assertMatch({Key, _, [Value, Value2]}, Get3)
     ,?_assertMatch({Key2, {error, key_enoent}}, GetFail)
    ].

test_size(_) ->
    Ns = "test",
    Set = "test-set",
    Key = "test-key",
    Key2 = <<"testkey2">>,

    Ldt = "mylset",

    SismemberValue = aerospike:lset_size(?POOLNAME, Ns, Set, Key, Ldt),
    SismemberFail = aerospike:lset_size(?POOLNAME, Ns, Set, Key, Ldt),
    SismemberFail2 = aerospike:lset_size(?POOLNAME, Ns, Set, Key2, Ldt),
    [
        ?_assertMatch(ok, SismemberValue)
        ,?_assertEqual({error, key_enoent}, SismemberFail)
        ,?_assertEqual({error, key_enoent}, SismemberFail2)
        ].

test_sremove(_) ->
    Ns = "test",
    Set = "test-set",
    Key = "test-key",
    Key2 = <<"testkey2">>,
    Value = 1,
    Ldt = "mylset",
    Value2 = 2,
    ok = aerospike:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, 0, Value2),
    ok = aerospike:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, 0, Value2),
    Get1 = aerospike:lset_get(?POOLNAME, Ns, Set, Key, Ldt),
    ok = aerospike:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, 0, Value),
    Get2 = aerospike:lset_get(?POOLNAME, Ns, Set, Key, Ldt),
    RemoveFail = aerospike:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, 0, Value),
    RemoveFail2 = aerospike:lset_remove(?POOLNAME, Ns, Set, Key2, Ldt, 0, Value),
    [?_assertMatch({Key, _, [Value]}, Get1),
     ?_assertEqual({Key, {error, key_enoent}}, Get2),
     ?_assertEqual({error, key_enoent}, RemoveFail),
     ?_assertEqual({error, key_enoent}, RemoveFail2)
    ].
