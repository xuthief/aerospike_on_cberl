-module(aerospike_sets_tests).
-include_lib("eunit/include/eunit.hrl").
-define(POOLNAME, testpool).

aerospike_test_() ->
    [{foreach, fun setup/0, fun clean_up/1,
      [
       fun test_sadd/1
       ,fun test_sismember/1
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
    Key = <<"testkey">>,
    Key2 = <<"testkey2">>,
    Value = 1,
    ok = aerospike:lset_add(?POOLNAME, Key, 0, Value),
    Get1 = aerospike:sget(?POOLNAME, Key),
    ok = aerospike:sadd(?POOLNAME, Key, 0, Value),
    Get2 = aerospike:sget(?POOLNAME, Key),
    Value2 = 2,
    ok = aerospike:sadd(?POOLNAME, Key, 0, Value2),
    Get3 = aerospike:sget(?POOLNAME, Key),
    GetFail = aerospike:sget(?POOLNAME, Key2),
    [?_assertMatch({Key, _, [Value]}, Get1)
     ,?_assertMatch({Key, _, [Value]}, Get2)
     ,?_assertMatch({Key, _, [Value, Value2]}, Get3)
     ,?_assertMatch({Key2, {error, key_enoent}}, GetFail)
    ].

test_sismember(_) ->
    Key = <<"testkey">>,
    Value = 1,
    Key2 = <<"testkey2">>,
    Value0 = 0,
    SismemberValue = aerospike:sismember(?POOLNAME, Key, 0, Value),
    SismemberFail = aerospike:sismember(?POOLNAME, Key, 0, Value0),
    SismemberFail2 = aerospike:sismember(?POOLNAME, Key2, 0, Value),
    [
     ?_assertMatch(ok, SismemberValue)
     ,?_assertEqual({error, key_enoent}, SismemberFail)
     ,?_assertEqual({error, key_enoent}, SismemberFail2)
    ].

test_sremove(_) ->
    Key = <<"testkey">>,
    Key2 = <<"testkey2">>,
    Value = 1,
    Value2 = 2,
    ok = aerospike:sremove(?POOLNAME, Key, 0, Value2),
    ok = aerospike:sremove(?POOLNAME, Key, 0, Value2),
    Get1 = aerospike:sget(?POOLNAME, Key),
    ok = aerospike:sremove(?POOLNAME, Key, 0, Value),
    Get2 = aerospike:sget(?POOLNAME, Key),
    RemoveFail = aerospike:sremove(?POOLNAME, Key, 0, Value),
    RemoveFail2 = aerospike:sremove(?POOLNAME, Key2, 0, Value),
    [?_assertMatch({Key, _, [Value]}, Get1),
     ?_assertEqual({Key, {error, key_enoent}}, Get2),
     ?_assertEqual({error, key_enoent}, RemoveFail),
     ?_assertEqual({error, key_enoent}, RemoveFail2)
    ].
