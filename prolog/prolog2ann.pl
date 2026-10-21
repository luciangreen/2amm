:- module(prolog2ann,
          [ convert_file/3,
            convert_clauses/3,
            ann_verify/3,
            ann_export_json/2,
            ann_extract/2
          ]).

:- use_module('prolog2ann/parse').
:- use_module('prolog2ann/normalise').
:- use_module('prolog2ann/ground').
:- use_module('prolog2ann/translate').
:- use_module('prolog2ann/emit').
:- use_module('prolog2ann/json_export').
:- use_module('prolog2ann/extract', []).
:- use_module('prolog2ann/runtime').
:- use_module(library(lists)).
:- use_module(library(error)).

%! convert_file(+Source, +Options, -Network) is det.
%
% Convert a finite-domain Prolog file to a step-mode network. Options may
% contain domain(File), out(File), json(File), module(Name), and
% limit(MaxAtoms).
convert_file(Source, Options, Network) :-
    option_value(mode, Options, step, Mode),
    ( Mode == step -> true ; throw(error(unsupported_mode(Mode), _)) ),
    option_value(limit, Options, 10000, Limit),
    must_be(positive_integer, Limit),
    option_value(step_limit, Options, none, StepLimit),
    ( StepLimit == none -> EmitOptions = []
    ; must_be(positive_integer, StepLimit),
      EmitOptions = [step_limit(StepLimit)]
    ),
    option_value(domain, Options, none, DomainFile),
    parse_file(Source, Parsed),
    normalise(Parsed, Normalised),
    domain_values(DomainFile, DomainValues),
    ground_program(Normalised, DomainValues, Ground, Limit, Atoms),
    translate(Ground, Atoms, Network),
    (   option_value(out, Options, none, Output),
        Output \== none
    ->  option_value(module, Options, prolog2ann_generated, Module),
        emit_network(Output, Module, Network, EmitOptions)
    ;   true
    ),
    (   option_value(json, Options, none, JsonFile),
        JsonFile \== none
    ->  export_json(JsonFile, Network)
    ;   true
    ).

%! ann_export_json(+File, +Network) is det.
%
% Export a translated network's neurons, edges, recurrent links, and traces as
% JSON.
ann_export_json(File, Network) :-
    export_json(File, Network).

%! ann_extract(+Network, -Clauses) is det.
%
% Reconstruct ground clauses from a step-mode network term or generated module.
ann_extract(Network, Clauses) :-
    prolog2ann_extract:ann_extract(Network, Clauses).

%! convert_clauses(+Clauses, +Options, -Network) is det.
%
% Convert in-memory facts and rules using the same finite-domain pipeline.
convert_clauses(Clauses, Options, Network) :-
    maplist(as_parsed_clause, Clauses, Parsed),
    normalise(Parsed, Normalised),
    option_value(mode, Options, step, Mode),
    ( Mode == step -> true ; throw(error(unsupported_mode(Mode), _)) ),
    option_value(domain_values, Options, [], DomainValues),
    option_value(limit, Options, 10000, Limit),
    ground_program(Normalised, DomainValues, Ground, Limit, Atoms),
    translate(Ground, Atoms, Network).

%! ann_verify(+Source, +Network, -Result) is det.
%
% Compare the source program's least model with a generated network. Network
% may be a network/7 term or the module name of a loaded generated network.
% Result is equivalent or mismatch(Missing, Unexpected).
ann_verify(Source, Network, Result) :-
    network_contents(Network, Atoms, NetworkRules, NetworkStrata, Module),
    network_domain_values(Atoms, DomainValues),
    parse_file(Source, Parsed),
    normalise(Parsed, Normalised),
    ground_program(Normalised, DomainValues, Ground, 10000, _),
    source_rules(Ground, SourceRules, SourceStrata),
    least_model(SourceRules, SourceStrata, Expected),
    network_model(Module, NetworkRules, NetworkStrata, Actual),
    subtract(Expected, Actual, Missing),
    subtract(Actual, Expected, Unexpected),
    (   Missing == [], Unexpected == []
    ->  Result = equivalent
    ;   Result = mismatch(Missing, Unexpected)
    ).

network_contents(network(Atoms, Rules, Strata, _, _, _, _),
                 Atoms, Rules, Strata, none) :-
    !.
network_contents(Module, Atoms, Rules, Strata, Module) :-
    atom(Module),
    (   current_predicate(Module:network_meta/1)
    ->  ( current_predicate(Module:network_atom/1)
        -> findall(Atom, Module:network_atom(Atom), Atoms0)
        ;  Atoms0 = []
        ),
        sort(Atoms0, Atoms),
        ( current_predicate(Module:network_rule/4)
        -> findall(rule(Head, Positive, Negative, Level),
                   Module:network_rule(Head, Positive, Negative, Level),
                   Rules0)
        ;  Rules0 = []
        ),
        sort(Rules0, Rules),
        ( current_predicate(Module:network_stratum/1)
        -> findall(Level, Module:network_stratum(Level), Strata0)
        ;  Strata0 = []
        ),
        sort(Strata0, Strata)
    ;   throw(error(domain_error(generated_network_module, Module), _))
    ).

network_domain_values(Atoms, Values) :-
    findall(Value,
            ( member(Atom, Atoms),
              sub_term(Value, Atom),
              atomic(Value)
            ),
            Values0),
    sort(Values0, Values).

source_rules(Ground, Rules, Strata) :-
    findall(rule(Head, Positive, Negative, Stratum),
            member(ground_clause(Head, Positive, Negative, _, _, _, _, Stratum),
                   Ground),
            Rules0),
    sort(Rules0, Rules),
    findall(Stratum, member(rule(_, _, _, Stratum), Rules), Strata0),
    sort(Strata0, Strata).

network_model(none, Rules, Strata, Model) :-
    !,
    least_model(Rules, Strata, Model).
network_model(Module, _, _, Model) :-
    prolog2ann_runtime:run_network(Module, Model, Steps, Reached),
    (   Reached == true
    ->  true
    ;   throw(error(no_fixpoint(Steps), _))
    ).

least_model(Rules, Strata, Model) :-
    least_model_strata(Strata, Rules, [], Model).

least_model_strata([], _, Model, Model).
least_model_strata([Stratum|Rest], Rules, Lower, Model) :-
    least_model_stratum(Rules, Stratum, Lower, Closed),
    least_model_strata(Rest, Rules, Closed, Model).

least_model_stratum(Rules, Stratum, Current, Model) :-
    findall(Head,
            ( member(rule(Head, Positive, Negative, Stratum), Rules),
              all_present(Positive, Current),
              all_absent(Negative, Current)
            ),
            Heads),
    append(Current, Heads, Combined),
    sort(Combined, Next),
    (   Next == Current
    ->  Model = Current
    ;   least_model_stratum(Rules, Stratum, Next, Model)
    ).

all_present([], _).
all_present([Atom|Rest], Atoms) :-
    memberchk(Atom, Atoms),
    all_present(Rest, Atoms).

all_absent([], _).
all_absent([Atom|Rest], Atoms) :-
    \+ memberchk(Atom, Atoms),
    all_absent(Rest, Atoms).

domain_values(none, []) :- !.
domain_values(File, Values) :-
    read_domain(File, Values).

as_parsed_clause((Head :- Body), clause(Head, Body, [], '<memory>', 1)) :- !.
as_parsed_clause(Head, clause(Head, true, [], '<memory>', 1)).

option_value(Name, Options, Default, Value) :-
    ( member(Option, Options), Option =.. [Name, Value] -> true
    ; Value = Default
    ).
