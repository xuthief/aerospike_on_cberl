-module(aserl_sets_tests).
-include_lib("eunit/include/eunit.hrl").
-include("aserl.hrl").
-define(POOLNAME, testpool).

aserl_test_() ->
    [{foreach, fun setup/0, fun clean_up/1,
      [
                fun do_clear/1
                ,fun test_sadd/1
                ,fun test_size/1
                ,fun test_sremove/1
                ]}].


%%%===================================================================
%%% Setup / Teardown
%%%===================================================================

setup() ->
    ?trace("start_link ~p", [?POOLNAME]),
    aserl:start_link(?POOLNAME, 1, "abj-as-3.yunba.io", 3000),
    ok.

clean_up(_) ->
    aserl:stop(?POOLNAME).

%%%===================================================================
%%% Tests
%%%===================================================================

do_clear(_) ->
    Ns = "test",
    Set = "test-set",
    Key = "test-key",
    Key2 = <<"testkey2">>,
    ?trace("remove ~p", [[Key, Key2]]),
    aserl:remove(?POOLNAME, Ns, Set, Key),
    aserl:remove(?POOLNAME, Ns, Set, Key2),
    [].

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
    ?trace("lset_add ~p - ~p", [Key, Value]),
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
     ,?_assertMatch({error, {aerospike_err_record_not_found, _ErrorMsg}}, GetFail)
    ].

test_size(_) ->
    Ns = "test",
    Set = "test-set",
    Key = "test-key",
    Key2 = <<"testkey2">>,

    Ldt = "mylset",

    SizeValue = aserl:lset_size(?POOLNAME, Ns, Set, Key, Ldt),
    SizeFail = aserl:lset_size(?POOLNAME, Ns, Set, Key2, Ldt),
    [
        ?_assertMatch({ok, 2}, SizeValue)
        ,?_assertMatch({error, {aerospike_err_record_not_found, _ErrorMsg}}, SizeFail)
        ].

test_sremove(_) ->
    Ns = "test",
    Set = "test-set",
    Key = "test-key",
    Key2 = <<"testkey2">>,
    Value = 1000,
    Ldt = "mylset",
    Value2 = 2,
    Remove1 = aserl:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, Value2, 0),
    RemoveFail1 = aserl:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, Value2, 0),
    Get1 = aserl:lset_get(?POOLNAME, Ns, Set, Key, Ldt),
    SRemove3 = aserl:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, Value, 0),
    Get2 = aserl:lset_get(?POOLNAME, Ns, Set, Key, Ldt),
    RemoveFail3 = aserl:lset_remove(?POOLNAME, Ns, Set, Key, Ldt, Value, 0),
    RemoveFail4 = aserl:lset_remove(?POOLNAME, Ns, Set, Key2, Ldt, Value, 0),
    [?_assertMatch({ok, [Value]}, Get1),
     ?_assertMatch(ok , Remove1),
     ?_assertMatch({error, {aerospike_err_large_item_not_found, _ErrorMsg}}, RemoveFail1),
     ?_assertMatch(ok , SRemove3),
     ?_assertMatch({ok, []}, Get2),
     ?_assertMatch({error, {aerospike_err_large_item_not_found, _ErrorMsg}}, RemoveFail3),
     ?_assertMatch({error, {aerospike_err_record_not_found, _ErrorMsg}}, RemoveFail4)
    ].
