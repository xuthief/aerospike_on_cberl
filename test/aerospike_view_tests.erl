-module(aerospike_view_tests).
-include_lib("eunit/include/eunit.hrl").
-define(POOLNAME, testpool).

aerospike_view_test_() ->
    [{foreach, fun setup/0, fun clean_up/1,
      [fun test_set_design_doc/1,
       fun test_remove_design_doc/1,
       fun test_query_view/1]}].


%%%===================================================================
%%% Setup / Teardown
%%%===================================================================

setup() ->
    aerospike:start_link(?POOLNAME, 3),
    aerospike:set_design_doc(?POOLNAME, "test-design-doc",
                         {[{<<"views">>,
                            {[{<<"test-view">>,
                               {[{<<"map">>, <<"function(doc,meta){}">>}]}
                              }]}
                           }]}),
    ok.

clean_up(_) ->
    aerospike:stop(?POOLNAME).

%%%===================================================================
%%% Tests
%%%===================================================================
test_query_view(_) ->
    DocName = "test-set-design-doc",
    ViewName = "test-view",
    [?_assertMatch({ok, {0, []}}, aerospike:view(?POOLNAME, DocName, ViewName, []))].

test_set_design_doc(_) ->
    DocName = "test-set-design-doc",
    ViewName = "test-view",
    DesignDoc = {[{<<"views">>,
                   {[{list_to_binary(ViewName),
                      {[{<<"map">>, <<"function(doc,meta){}">>}]}
                     }]}
                  }]},
    fun () ->
        [?assertEqual(ok, aerospike:set_design_doc(?POOLNAME, DocName, DesignDoc)),
         ?assertMatch({ok, _}, aerospike:view(?POOLNAME, DocName, ViewName, []))]
    end.

test_remove_design_doc(_) ->
    DocName = "test-design-doc",
    ViewName = "test-view",
    fun () ->
        [?assertEqual(ok, aerospike:remove_design_doc(?POOLNAME, DocName)),
         ?assertMatch({error, _}, aerospike:view(?POOLNAME, DocName, ViewName, []))]
    end.
