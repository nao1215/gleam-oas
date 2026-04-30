-module(oaspec_test_helpers_ffi).

%% Test-only helpers for capturing side effects from Gleam closures.
%% Uses the process dictionary so each test process gets isolated
%% state without needing to plumb a `Subject` through the function
%% under test. Only used by `progress_test.gleam`.

-export([pdict_get/1, pdict_reset/1]).

%% Wrap erlang:get/1 so the Gleam side sees `Result(value, Nil)`.
%% Returning a Result keeps the call site free of dynamic-typing
%% boilerplate at the cost of one extra call, which is negligible
%% in tests.
-spec pdict_get(term()) -> {ok, term()} | {error, nil}.
pdict_get(Key) ->
    case erlang:get(Key) of
        undefined -> {error, nil};
        Value -> {ok, Value}
    end.

%% Reset a key by erasing it. Returns nil so the Gleam-facing type
%% is uniform with `pdict_get` callers that throw away the result.
-spec pdict_reset(term()) -> nil.
pdict_reset(Key) ->
    erlang:erase(Key),
    nil.
