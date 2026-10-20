:- module(prolog2ann_emit, [emit_network/3]).

:- use_module(library(lists)).

%! emit_network(+File, +Module, +Network) is det.
%
% Write deterministic Prolog facts and wrappers for a generated network.
emit_network(File, Module, network(Atoms, Rules, Strata, Traces)) :-
    setup_call_cleanup(
        open(File, write, Stream, [encoding(utf8)]),
        emit_terms(Stream, Module, Atoms, Rules, Strata, Traces),
        close(Stream)).

emit_terms(Stream, Module, Atoms, Rules, Strata, Traces) :-
    format(Stream, ':- module(~q, [ann_query/2, ann_query_all/2, ann_run/3]).~n', [Module]),
    format(Stream, ':- use_module(library(prolog2ann/runtime)).~n~n', []),
    format(Stream, 'network_meta(mode(step)).~n', []),
    maplist(emit_atom(Stream), Atoms),
    maplist(emit_rule(Stream), Rules),
    maplist(emit_stratum(Stream), Strata),
    maplist(emit_trace(Stream), Traces),
    format(Stream, '~nann_query(Goal, Truth) :- prolog2ann_runtime:ann_query(~q, Goal, Truth).~n', [Module]),
    format(Stream, 'ann_query_all(Pattern, Solutions) :- prolog2ann_runtime:ann_query_all(~q, Pattern, Solutions).~n', [Module]),
    format(Stream, 'ann_run(Atoms, Steps, Reached) :- prolog2ann_runtime:run_network(~q, Atoms, Steps, Reached).~n', [Module]).

emit_atom(Stream, Atom) :-
    write_fact(Stream, network_atom(Atom)).

emit_rule(Stream, rule(Head, Positive, Negative, Stratum)) :-
    write_fact(Stream, network_rule(Head, Positive, Negative, Stratum)).

emit_stratum(Stream, Stratum) :-
    write_fact(Stream, network_stratum(Stratum)).

emit_trace(Stream, Trace) :-
    write_fact(Stream, Trace).

write_fact(Stream, Term) :-
    write_term(Stream, Term, [quoted(true), numbervars(true)]),
    write(Stream, '.'),
    nl(Stream).
