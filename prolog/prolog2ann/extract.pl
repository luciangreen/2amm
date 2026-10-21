:- module(prolog2ann_extract, [ann_extract/2]).

:- use_module(library(error)).
:- use_module(library(lists)).

%! ann_extract(+Network, -Clauses) is det.
%
% Reconstruct ground Prolog clauses from a step-mode network term or a loaded
% generated network module. The extracted clauses preserve the represented
% rules and stratified negation, but not the original variables or source text.
ann_extract(Network, Clauses) :-
    network_rules(Network, Rules),
    maplist(extract_rule, Rules, Clauses).

network_rules(network(_, Rules, _, _, _, _, _), Rules) :-
    !,
    must_be(list, Rules).
network_rules(Module, Rules) :-
    atom(Module),
    !,
    (   current_predicate(Module:network_meta/1),
        once(Module:network_meta(mode(step)))
    ->  (   current_predicate(Module:network_rule/4)
        ->  findall(rule(Head, Positive, Negative, Stratum),
                    Module:network_rule(Head, Positive, Negative, Stratum),
                    Rules0),
            sort(Rules0, Rules)
        ;   Rules = []
        )
    ;   throw(error(domain_error(step_mode_network, Module), _))
    ).
network_rules(Network, _) :-
    throw(error(type_error(network_or_module, Network), _)).

extract_rule(rule(Head, Positive, Negative, _), Clause) :-
    maplist(negate, Negative, NegativeGoals),
    append(Positive, NegativeGoals, Goals),
    conjunction(Goals, Body),
    (   Body == true
    ->  Clause = Head
    ;   Clause = (Head :- Body)
    ).

negate(Goal, \+ Goal).

conjunction([], true).
conjunction([Goal|Goals], Body) :-
    conjunction_rest(Goals, Goal, Body).

conjunction_rest([], Body, Body).
conjunction_rest([Goal|Goals], Prefix, (Prefix, Body)) :-
    conjunction_rest(Goals, Goal, Body).
