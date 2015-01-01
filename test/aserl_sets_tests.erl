-module(aserl_sets_tests).
-include_lib("eunit/include/eunit.hrl").
-define(POOLNAME, testpool).

aserl_test_() ->
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
    Ns = "test",
    Set = "test-set",
    Key = "test-key",
    Key2 = <<"testkey2">>,
    {ok, _} = aserl:start_link(?POOLNAME, 1, "10.37.129.7", 3000, "", ""),
    aserl:remove(?POOLNAME, Ns, Set, Key),
    aserl:remove(?POOLNAME, Ns, Set, Key2),
    ok.

clean_up(_) ->
    aserl:stop(?POOLNAME).

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
    ok = aserl:lset_add(?POOLNAME, Ns, Set, Key, Ldt, Value, 1000),
    Get1 = aserl:lset_get(?POOLNAME, Ns, Set, Key, Ldt, 100),
    _ADD2 = aserl:lset_add(?POOLNAME, Ns, Set, Key, Ldt, Value, 0),
    Get2 = aserl:lset_get(?POOLNAME, Ns, Set, Key, Ldt, 0),
    Value2 = 2,
    _ADD3 = aserl:lset_add(?POOLNAME, Ns, Set, Key, Ldt, Value2),
    Get3 = aserl:lset_get(?POOLNAME, Ns, Set, Key, Ldt),
    GetFail = aserl:lset_get(?POOLNAME, Ns, Set, Key2, Ldt),
    [?_assertMatch({ok, [Value]}, Get1)
     ,?_assertMatch({ok, [Value]}, Get2)
     ,?_assertMatch({ok, [Value, Value2]}, Get3)
     ,?_assertMatch({Key2, {error, key_enoent}}, GetFail)
    ].

test_size(_) ->
    Ns = "test",
    Set = "test-set",
    Key = "test-key",
    Key2 = <<"testkey2">>,

    Ldt = "mylset",

    SismemberValue = aserl:lset_size(?POOLNAME, Ns, Set, Key, Ldt),
    SismemberFail = aserl:lset_size(?POOLNAME, Ns, Set, Key, Ldt),
    SismemberFail2 = aserl:lset_size(?POOLNAME, Ns, Set, Key2, Ldt),
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
    ok = aserl:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, 0, Value2),
    ok = aserl:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, 0, Value2),
    Get1 = aserl:lset_get(?POOLNAME, Ns, Set, Key, Ldt),
    ok = aserl:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, 0, Value),
    Get2 = aserl:lset_get(?POOLNAME, Ns, Set, Key, Ldt),
    RemoveFail = aserl:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, 0, Value),
    RemoveFail2 = aserl:lset_remove(?POOLNAME, Ns, Set, Key2, Ldt, 0, Value),
    [?_assertMatch({Key, _, [Value]}, Get1),
     ?_assertEqual({Key, {error, key_enoent}}, Get2),
     ?_assertEqual({error, key_enoent}, RemoveFail),
     ?_assertEqual({error, key_enoent}, RemoveFail2)
    ].
