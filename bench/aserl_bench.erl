#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ./ebin -pa ./deps/poolboy/ebin -Wall -smp enable -name aserl_bench@127.0.0.1 -setcookie aserl_bench -mnesia debug verbose
%%
-module(aserl_sets_bench).

-define(PROC_COUNT, 20).
-define(VAL_COUNT, 10000).

%%%===================================================================
%%% Setup / Teardown
%%%===================================================================

-define(PoolNamePrefix, testpool).
-define(Ns, "topic").
-define(Set, "test-set").
-define(Ldt, "mylset").

-define(KeyPrefix, "bench-key").
-define(ValuePrefix, "bench-value").

setup(Index) ->
    PoolName = list_to_atom(lists:concat([?PoolNamePrefix, Index])),
    {ok, _} = aserl:start_link(PoolName, 20, "abj-as2-1.yunba.io", 3000),
    PoolName.

clean_up(PoolName) ->
    ok = aserl:stop(PoolName).

add_val(_PoolName, _Key, ?VAL_COUNT) ->
    ok;
add_val(PoolName, Key, Index) ->
    Val = lists:concat([?ValuePrefix, Index]),
    ok = aserl:lset_add(PoolName, ?Ns, ?Set, Key, ?Ldt, Val,  1000),
    add_val(PoolName, Key, Index+1).

add_key(PoolName, Index) ->
    Key = lists:concat([?KeyPrefix, Index]),
    aserl:remove(PoolName, ?Ns, ?Set, Key),
    add_val(PoolName, Key, 0).

%%%===================================================================
%%% Tests
%%%===================================================================

main([]) ->
    Pid = self(),
    L = lists:seq(1, ?PROC_COUNT),
    {Mega1,Sec1,_Micro1} = erlang:now(),
    lists:map(fun(I) ->
                spawn(fun()->
                            try
                                PoolName = setup(I),
                                add_key(PoolName, I),
                                clean_up(PoolName),
                                Pid ! ok
                            catch
                                _Type:Err ->
                                    io:format("do test failed in index[~p] Err[~p]~n", [I, Err]),
                                    Pid ! Err
                            end
                    end)
        end, L),

    lists:map(fun(_) ->
                receive
                    ok -> ok;
                    Err -> 
                        io:format("do test failed in Err[~p]~n", [Err])
                end
        end, L),
    {Mega2,Sec2,_Micro2} = erlang:now(),
    AllCount = ?PROC_COUNT * ?VAL_COUNT,
    AllSec = (Mega2*1000000+Sec2)- (Mega1*1000000+Sec1),
    io:format("all test ~p add done in ~p sec with ~p procs ~nas ~ftps~n", [AllCount, AllSec, ?PROC_COUNT, AllCount/AllSec]).
