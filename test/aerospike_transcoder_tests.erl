-module(aerospike_transcoder_tests).
-include_lib("eunit/include/eunit.hrl").

aerospike_transcoder_test_() ->
    [
        ?_assertEqual("abc", aerospike_transcoder:decode_value(
            aerospike_transcoder:flag(json), aerospike_transcoder:encode_value(json, "abc"))),
        %?_assertEqual(list_to_binary("abc"), aerospike_transcoder:decode_value(
        %    aerospike_transcoder:flag(raw_binary), aerospike_transcoder:encode_value(raw_binary, "abc"))),
        ?_assertEqual("abc", aerospike_transcoder:decode_value(
            aerospike_transcoder:flag(str), aerospike_transcoder:encode_value(str, "abc"))),
        ?_assertEqual("abc", aerospike_transcoder:decode_value(
            aerospike_transcoder:flag([json, str]), aerospike_transcoder:encode_value([json,str], "abc")))
        %,?_assertEqual(list_to_binary("abc"), aerospike_transcoder:decode_value(
        %    aerospike_transcoder:flag([raw_binary, str]), aerospike_transcoder:encode_value([raw_binary,str], "abc")))
    ].
