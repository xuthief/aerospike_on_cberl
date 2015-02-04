CBERL
====

[![Build Status](https://travis-ci.org/chitika/aerospike.svg?branch=master)](https://travis-ci.org/chitika/aerospike)

NIF based Erlang bindings for aerospike based on libaerospike. 
CBERL is at early stage of development, it only supports very basic functionality. Please submit bugs and patches if you find any.
Tested on mac, debian squeeze and amazon linux.

Quick Setup/Start
---------
First you must have lua5.1 installed. 

    curl -R -O http://www.lua.org/ftp/lua-5.1.tar.gz

Then:

    git clone git@github.com:chitika/aerospike.git

Then, get git submodules:

    cd aerospike
    git submodule update --init --remote --recursive

Then:

    ### assuming you have rebar in your path
    ./rebar get-deps compile

Or just include it as a dependency in your rebar config.

   

Aserl-error
-------

```
    cat c/src/include/aerospike/as_status.h | grep "AEROSPIKE_[A-Z_]*\>.*=" | sed 's/^.*AEROSPIKE_/AEROSPIKE_/g' |  sed 's/[ ]*//g' | sed "s/`echo -e \\\t`*//g" | sed "s/,*//g" | awk -F"=" '{print "-define("$1", ",$2")."}' > include/aserl_error.hrl
```
   

Example
-------

Make sure you have aerospike running on localhost or use aerospike:new(Host) instead.

    %% create a connection pool  of 5 connections named aerospike_default
    %% you can provide more argument like host, username, password, 
    %% bucket and transcoder - look at [aerospike.erl](https://github.com/wcummings/aerospike/blob/master/src/aerospike.erl) for more detail 
    aerospike:start_link(aerospike_default, 5).
    {ok, <0.33.0>}
    %% Poolname, Key, Expire - 0 for infinity, Value
    aerospike:set(aerospike_default, <<"fkey">>, 0, <<"aerospike">>).
    ok
    aerospike:get(aerospike_default, <<"fkey">>).
    {<<"fkey">>, ReturnedCasValue, <<"aerospike">>}

For more information on all the functions -> ./rebar doc (most of documentation is out of date right now)

Performance
-------

I included [results](https://github.com/wcummings/aerospike/blob/master/bench/macmini_aerospike_new.png) of [basho_bench](http://docs.basho.com/riak/latest/cookbooks/Benchmarking/) which I ran on my mac. It is the results of 100 processes using a pool of 5 connections. I included basha_bench driver and config file under bench. Please tweak the config file for your requirement and run your own benchmarks.

TODO
----

1) Update documentation

2) Write more tests
