-module(aserl_sets_tests).
-include_lib("eunit/include/eunit.hrl").
-include("../include/aserl.hrl").
-include_lib("../include/aserl_error.hrl").

-define(POOLNAME, testpool).
-define(POOLNAME2, testpool2).

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
    {ok, _} = aserl:start_link(?POOLNAME, 5, "abj-as-2.yunba.io", 3000),
    {ok, _} = aserl:start_link(?POOLNAME2, 1, "abj-as-2.yunba.io", 3000),
    ok.

clean_up(_) ->
    ok = aserl:stop(?POOLNAME2),
    ok = aserl:stop(?POOLNAME).

%%%===================================================================
%%% Tests
%%%===================================================================

-define(Ns, "topic").
-define(Set, "test-set").
-define(Ldt, "mylset").

-define(Key1, "test-key").
-define(Key2, <<"test-key2">>).
-define(Value1, "test-value1").
-define(Value2, <<"test-value1">>).

do_clear(_) ->
    ?trace("remove ~p", [[?Key1, ?Key2]]),
    aserl:remove(?POOLNAME, ?Ns, ?Set, ?Key1),
    aserl:remove(?POOLNAME, ?Ns, ?Set, ?Key2),
    [].

%%%===================================================================
%%% Tests
%%%===================================================================

test_sadd(_) ->
    ?trace("lset_add ~p - ~p", [?Key1, ?Value1]),
    ok = aserl:lset_add(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt, ?Value1, 1000),
    Get1 = aserl:lset_get(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt, 100),
    {error, {?AEROSPIKE_ERR_UDF, _Err}} = aserl:lset_add(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt, ?Value1, 0),
    Get2 = aserl:lset_get(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt, 0),
    ok = aserl:lset_add(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt, ?Value2),
    Get3 = aserl:lset_get(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt),
    GetFail = aserl:lset_get(?POOLNAME, ?Ns, ?Set, ?Key2, ?Ldt),
    [?_assertMatch({ok, [?Value1]}, Get1)
     ,?_assertMatch({ok, [?Value1]}, Get2)
     ,?_assertMatch({ok, [?Value1, ?Value2]}, Get3)
     ,?_assertMatch({error, {?AEROSPIKE_ERR_RECORD_NOT_FOUND, _ErrorMsg}}, GetFail)
    ].

test_size(_) ->
    SizeValue = aserl:lset_size(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt),
    SizeFail = aserl:lset_size(?POOLNAME, ?Ns, ?Set, ?Key2, ?Ldt),
    [
        ?_assertMatch({ok, 2}, SizeValue)
        ,?_assertMatch({error, {?AEROSPIKE_ERR_RECORD_NOT_FOUND, _ErrorMsg}}, SizeFail)
        ].

test_sremove(_) ->
    Remove1 = aserl:lset_remove(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt, ?Value2, 0),
    RemoveFail1 = aserl:lset_remove(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt, ?Value2, 0),
    Get1 = aserl:lset_get(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt),
    SRemove3 = aserl:lset_remove(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt, ?Value1, 0),
    Get2 = aserl:lset_get(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt),
    RemoveFail3 = aserl:lset_remove(?POOLNAME, ?Ns, ?Set, ?Key1, ?Ldt, ?Value1, 0),
    RemoveFail4 = aserl:lset_remove(?POOLNAME, ?Ns, ?Set, ?Key2, ?Ldt, ?Value1, 0),
    [?_assertMatch({ok, [?Value1]}, Get1),
     ?_assertMatch(ok , Remove1),
     ?_assertMatch({error, {?AEROSPIKE_ERR_LARGE_ITEM_NOT_FOUND, _ErrorMsg}}, RemoveFail1),
     ?_assertMatch(ok , SRemove3),
     ?_assertMatch({ok, []}, Get2),
     ?_assertMatch({error, {?AEROSPIKE_ERR_LARGE_ITEM_NOT_FOUND, _ErrorMsg}}, RemoveFail3),
     ?_assertMatch({error, {?AEROSPIKE_ERR_RECORD_NOT_FOUND, _ErrorMsg}}, RemoveFail4)
    ].
