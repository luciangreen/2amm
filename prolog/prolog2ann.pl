:- module(prolog2ann,
          [ convert_file/3,
            convert_clauses/3,
            ann_verify/3
          ]).

:- use_module('prolog2ann/parse').
:- use_module('prolog2ann/normalise').
:- use_module('prolog2ann/ground').
:- use_module('prolog2ann/translate').
:- use_module('prolog2ann/emit').
:- use_module(library(lists)).
:- use_module(library(error)).

%! convert_file(+Source, +Options, -Network) is det.
%
% Convert a finite-domain Prolog file to a step-mode network. Options may
% contain domain(File), out(File), module(Name), and limit(MaxAtoms).
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
    (   option_value(out, Options, none, Output)
    ->  option_value(module, Options, prolog2ann_generated, Module),
        emit_network(Output, Module, Network, EmitOptions)
    ;   true
    ).

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
% Placeholder; raises not_implemented until source equivalence checking lands.
ann_verify(_, _, _) :-
    throw(error(not_implemented(ann_verify/3), _)).

domain_values(none, []) :- !.
domain_values(File, Values) :-
    read_domain(File, Values).

as_parsed_clause((Head :- Body), clause(Head, Body, [], '<memory>', 1)) :- !.
as_parsed_clause(Head, clause(Head, true, [], '<memory>', 1)).

option_value(Name, Options, Default, Value) :-
    ( member(Option, Options), Option =.. [Name, Value] -> true
    ; Value = Default
    ).
