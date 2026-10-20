#!/usr/bin/env swipl
:- initialization(main, main).

:- prolog_load_context(directory, BinDirectory),
   directory_file_path(BinDirectory, '../prolog', LibraryDirectory),
   absolute_file_name(LibraryDirectory, AbsoluteLibraryDirectory),
   asserta(user:file_search_path(library, AbsoluteLibraryDirectory)).

:- use_module('../prolog/prolog2ann').

main :-
    current_prolog_flag(argv, Arguments),
    catch(run(Arguments), Error, (print_message(error, Error), halt(2))).

run([convert, Source|Arguments]) :-
    parse_options(Arguments, Options),
    prolog2ann:convert_file(Source, Options, network(Atoms, _, _, _, _, _, _)),
    length(Atoms, Size),
    format('Converted ~w atoms to step-mode network (~d atoms).~n', [Source, Size]).
run([query, NetworkFile, GoalText]) :-
    load_files(NetworkFile, []),
    network_module(NetworkFile, Module),
    read_term_from_atom(GoalText, Goal, []),
    Module:ann_query(Goal, Truth),
    format('~q: ~q~n', [Goal, Truth]).
run([verify, _Source, _Network]) :-
    throw(error(not_implemented(verify), _)).
run(_) :-
    format(user_error,
           'Usage: swipl bin/prolog2ann.pl convert SOURCE [--domain FILE] [--mode step] [--limit N] [--step-limit N] --out FILE~n       swipl bin/prolog2ann.pl query NETWORK.pl \"ground_atom\"~n',
           []),
    halt(2).

parse_options([], []).
parse_options(['--domain', File|Rest], [domain(File)|Options]) :-
    !, parse_options(Rest, Options).
parse_options(['--out', File|Rest], [out(File)|Options]) :-
    !, parse_options(Rest, Options).
parse_options(['--module', Name|Rest], [module(Module)|Options]) :-
    !, text_atom(Name, Module), parse_options(Rest, Options).
parse_options(['--mode', ModeString|Rest], [mode(Mode)|Options]) :-
    !, text_atom(ModeString, Mode), parse_options(Rest, Options).
parse_options(['--limit', LimitString|Rest], [limit(Limit)|Options]) :-
    !, text_string(LimitString, LimitText), number_string(Limit, LimitText),
    parse_options(Rest, Options).
parse_options(['--step-limit', LimitString|Rest], [step_limit(Limit)|Options]) :-
    !, text_string(LimitString, LimitText), number_string(Limit, LimitText),
    parse_options(Rest, Options).
parse_options([Unknown|_], _) :-
    throw(error(unknown_option(Unknown), _)).

network_module(File, Module) :-
    setup_call_cleanup(
        open(File, read, Stream),
        ( read_term(Stream, Directive, []),
          Directive = (:- module(Module, _))
        ),
        close(Stream)).

text_atom(Value, Atom) :-
    ( atom(Value) -> Atom = Value ; atom_string(Atom, Value) ).

text_string(Value, String) :-
    ( string(Value) -> String = Value ; atom_string(Value, String) ).
