:- module(prolog2ann_translate, [translate/3]).

:- use_module(library(lists)).

%! translate(+GroundClauses, +Atoms, -Network) is det.
%
% Convert grounded clauses into a deterministic list-based network model.
translate(GroundClauses, Atoms,
          network(Atoms, Rules, Strata, Traces, Neurons, Edges, Recurrent)) :-
    findall(rule(Head, Positive, Negative, Stratum),
            member(ground_clause(Head, Positive, Negative, _, _, _, _, Stratum),
                   GroundClauses),
            Rules0),
    sort(Rules0, Rules),
    findall(Stratum, member(rule(_, _, _, Stratum), Rules), Strata0),
    sort(Strata0, Strata),
    source_traces(GroundClauses, Traces),
    maplist(atom_neurons, Atoms, AtomNeurons),
    findall(neuron(hidden(Id), hidden, step, Threshold),
            ( nth1(Id, GroundClauses,
                   ground_clause(_, Positive, _, _, _, _, _, _)),
              length(Positive, PositiveCount),
              Threshold is PositiveCount - 0.5
            ),
            HiddenNeurons),
    append(AtomNeurons, FlatAtomNeurons),
    append(FlatAtomNeurons, HiddenNeurons, Neurons),
    findall(edge(in(Body), hidden(Id), 1.0),
            ( nth1(Id, GroundClauses,
                   ground_clause(_, Positive, _, _, _, _, _, _)),
              member(Body, Positive)
            ),
            PositiveEdges),
    findall(edge(in(Body), hidden(Id), -1.0),
            ( nth1(Id, GroundClauses,
                   ground_clause(_, _, Negative, _, _, _, _, _)),
              member(Body, Negative)
            ),
            NegativeEdges),
    findall(edge(hidden(Id), out(Head), 1.0),
            nth1(Id, GroundClauses,
                 ground_clause(Head, _, _, _, _, _, _, _)),
            HeadEdges),
    append([PositiveEdges, NegativeEdges, HeadEdges], Edges),
    findall(recurrent(out(Atom), in(Atom)), member(Atom, Atoms), Recurrent).

source_traces(GroundClauses, Traces) :-
    findall(trace(hidden(Id), Id, File, Line),
            nth1(Id, GroundClauses,
                 ground_clause(_, _, _, _, _, File, Line, _)),
            HiddenTraces),
    findall(trace(Neuron, Id, File, Line),
            ( nth1(Id, GroundClauses,
                   ground_clause(Head, Positive, Negative, _, _, File, Line, _)),
              append([Head|Positive], Negative, Atoms0),
              sort(Atoms0, ClauseAtoms),
              member(Atom, ClauseAtoms),
              member(Neuron, [in(Atom), out(Atom)])
            ),
            AtomTraces),
    append(HiddenTraces, AtomTraces, Traces0),
    sort(Traces0, Traces).

atom_neurons(Atom, [neuron(in(Atom), input, linear, 0.0),
                    neuron(out(Atom), output, step, 0.5)]).
