:- module(prolog2ann_emit, [emit_network/3, emit_network/4]).

:- use_module(library(lists)).

%! emit_network(+File, +Module, +Network) is det.
%
% Write deterministic Prolog facts and wrappers for a generated network.
emit_network(File, Module,
            Network) :-
    emit_network(File, Module, Network, none).

%! emit_network(+File, +Module, +Network, +StepLimit) is det.
%
% Write a generated network, optionally with a per-stratum runtime step limit.
emit_network(File, Module,
            network(Atoms, Rules, Strata, Traces, Neurons, Edges, Recurrent),
            StepLimit) :-
    setup_call_cleanup(
        open(File, write, Stream, [encoding(utf8)]),
        emit_terms(Stream, Module, Atoms, Rules, Strata, Traces,
                  Neurons, Edges, Recurrent, StepLimit),
        close(Stream)).

emit_terms(Stream, Module, Atoms, Rules, Strata, Traces,
           Neurons, Edges, Recurrent, StepLimit) :-
    format(Stream,
           ':- module(~q, [ann_query/2, ann_query_all/2, ann_run/3, neuron/4, edge/3, recurrent/2, trace/4]).~n',
           [Module]),
    format(Stream, ':- use_module(library(prolog2ann/runtime)).~n~n', []),
    format(Stream, 'network_meta(mode(step)).~n', []),
    emit_step_limit(Stream, StepLimit),
    maplist(emit_atom(Stream), Atoms),
    maplist(emit_rule(Stream), Rules),
    maplist(emit_stratum(Stream), Strata),
    maplist(write_fact(Stream), Neurons),
    maplist(write_fact(Stream), Edges),
    maplist(write_fact(Stream), Recurrent),
    maplist(emit_trace(Stream), Traces),
    format(Stream, '~nann_query(Goal, Truth) :- prolog2ann_runtime:ann_query(~q, Goal, Truth).~n', [Module]),
    format(Stream, 'ann_query_all(Pattern, Solutions) :- prolog2ann_runtime:ann_query_all(~q, Pattern, Solutions).~n', [Module]),
    format(Stream, 'ann_run(Atoms, Steps, Reached) :- prolog2ann_runtime:run_network(~q, Atoms, Steps, Reached).~n', [Module]).

emit_step_limit(_, none) :- !.
emit_step_limit(Stream, Limit) :-
    format(Stream, 'network_step_limit(~d).~n', [Limit]).

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
