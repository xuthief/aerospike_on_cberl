ASERL
====

NIF based Erlang bindings for aerospike based on aerospike c sdk and cberl. 
ASERL is at early stage of development, it only supports very basic functionality. Please submit bugs and patches if you find any.
Tested on mac and amazon linux.

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


get source(.c) file for rebar.config
-------

```
    for file in `grep "\.c\b" ~/debug.make.log | grep "^cc\b" | awk '{print $NF}' | grep -v "\btarget\/"`; do filename=`echo $file | awk -F"/" '{print $NF}'`; find c -name $filename | grep "$file"; done
```

aserl-error
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
Here is benchmark of lset_add(ldt, run ($escript bench/aserl_bench.erl))
all test 200000 add done in 89 sec with 20 procs
as 2247.191011tps


TODO
----

1) Update documentation

2) Write more tests
