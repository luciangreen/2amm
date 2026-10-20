:- module(test_prolog2ann, []).

:- use_module('../prolog/prolog2ann').
:- use_module('../prolog/prolog2ann/parse').
:- use_module('../prolog/prolog2ann/normalise').
:- use_module('../prolog/prolog2ann/ground').
:- use_module('../prolog/prolog2ann/translate').
:- use_module('../prolog/prolog2ann/emit').
:- use_module('../prolog/prolog2ann/runtime').
:- use_module(library(plunit)).

:- dynamic examples_directory/1.

:- prolog_load_context(directory, TestDirectory),
   directory_file_path(TestDirectory, '../examples', ExamplesDirectory),
   absolute_file_name(ExamplesDirectory, AbsoluteExamples),
   assertz(examples_directory(AbsoluteExamples)).

:- begin_tests(prolog2ann).

test(parse_example) :-
    example(ancestor, File),
    parse_file(File, Clauses),
    length(Clauses, 9).

test(reject_cut_with_source_line) :-
    example(cut, File),
    catch(parse_file(File, _), Error, true),
    assertion(nonvar(Error)),
    assertion(Error = error(unsupported_construct(!), file(File, 2))).

test(reject_non_stratified_negation) :-
    Parsed = [ clause(p(X), \+ q(X), [], sample, 1),
               clause(q(X), p(X), [], sample, 2)
             ],
    catch(normalise(Parsed, _), Error, true),
    assertion(nonvar(Error)),
    assertion(Error = error(non_stratified_negation(Cycle), file(sample, 1))),
    assertion(memberchk(p/1, Cycle)).

test(grounding_limit) :-
    example(ancestor, File),
    example(ancestor_domain, Domain),
    parse_file(File, Parsed),
    normalise(Parsed, Normalised),
    read_domain(Domain, Values),
    catch(ground_program(Normalised, Values, _, 1, _), Error, true),
    assertion(nonvar(Error)),
    assertion(Error = error(herbrand_base_limit(_, 1), _)).

test(finite_domain_required_for_variables) :-
    Parsed = [clause(p(X), true, [], sample, 1)],
    normalise(Parsed, Normalised),
    catch(ground_program(Normalised, [], _, 10000, _), Error, true),
    assertion(nonvar(Error)),
    assertion(Error = error(finite_domain_required, _)).

test(translation_includes_weighted_neurons) :-
    convert_clauses([p(a), (q(X) :- p(X))],
                    [domain_values([a])],
                    network(_, _, _, _, Neurons, Edges, Recurrent)),
    assertion(memberchk(neuron(hidden(2), hidden, step, 0.5), Neurons)),
    assertion(memberchk(edge(in(p(a)), hidden(2), 1.0), Edges)),
    assertion(memberchk(edge(hidden(2), out(q(a)), 1.0), Edges)),
    assertion(memberchk(recurrent(out(p(a)), in(p(a))), Recurrent)).

test(stratified_negation_and_query) :-
    example(flies, File),
    parse_file(File, Parsed),
    normalise(Parsed, Normalised),
    ground_program(Normalised, [], Ground, 10000, Atoms),
    translate(Ground, Atoms, Network),
    temporary_network(Network, Module, Path),
    setup_call_cleanup(
        true,
        ( ann_query(Module, flies(tweety), true),
          ann_query(Module, flies(pingu), false),
          ann_query_all(Module, flies(X), Solutions),
          assertion(Solutions == [flies(polly), flies(tweety)]),
          assertion(var(X))
        ),
        ( unload_file(Path), delete_file(Path) )).

test(mutual_recursion_with_integer_range) :-
    example(even_odd, File),
    example(even_odd_domain, Domain),
    parse_file(File, Parsed),
    normalise(Parsed, Normalised),
    read_domain(Domain, Values),
    ground_program(Normalised, Values, Ground, 10000, Atoms),
    translate(Ground, Atoms, Network),
    temporary_network(Network, Module, Path),
    setup_call_cleanup(
        true,
        ( ann_query(Module, even(4), true),
          ann_query(Module, odd(3), true),
          ann_query(Module, even(3), false)
        ),
        ( unload_file(Path), delete_file(Path) )).

test(convert_file_creates_output) :-
    example(ancestor, File),
    example(ancestor_domain, Domain),
    tmp_file(prolog2ann, Output),
    setup_call_cleanup(
        true,
        ( convert_file(File, [domain(Domain), out(Output), module(test_generated)], _),
          exists_file(Output),
          setup_call_cleanup(
              true,
              ( load_files(Output, []),
                test_generated:ann_query(ancestor(ann, dee), true)
              ),
              unload_file(Output))
        ),
        ( exists_file(Output) -> delete_file(Output) ; true )).

:- end_tests(prolog2ann).

example(Name, File) :-
    examples_directory(Examples),
    atomic_list_concat([Examples, '/', Name, '.pl'], File).

temporary_network(Network, Module, Path) :-
    tmp_file(prolog2ann, Path),
    Module = test_generated_network,
    emit_network(Path, Module, Network),
    load_files(Path, []).
