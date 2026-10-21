:- module(prolog2ann_json_export, [export_json/2]).

:- use_module(library(http/json)).
:- use_module(library(lists)).

%! export_json(+File, +Network) is det.
%
% Write the inspectable step-mode network representation as JSON.
export_json(File,
            network(Atoms, _, _, Traces, Neurons, Edges, Recurrent)) :-
    maplist(term_json, Atoms, JsonAtoms),
    maplist(neuron_json, Neurons, JsonNeurons),
    maplist(edge_json, Edges, JsonEdges),
    maplist(recurrent_json, Recurrent, JsonRecurrent),
    maplist(trace_json, Traces, JsonTraces),
    Dict = _{mode: "step",
             atoms: JsonAtoms,
             neurons: JsonNeurons,
             edges: JsonEdges,
             recurrent: JsonRecurrent,
             traces: JsonTraces},
    setup_call_cleanup(
        open(File, write, Stream, [encoding(utf8)]),
        ( json_write_dict(Stream, Dict, [width(0)]),
          nl(Stream)
        ),
        close(Stream)).

atom_json(Term, String) :-
    atom_string(Term, String).

term_json(Term, String) :-
    term_string(Term, String, [quoted(true), numbervars(true)]).

neuron_json(neuron(Id, Layer, Activation, Threshold),
            _{id: IdString,
              layer: LayerString,
              activation: ActivationString,
              threshold: Threshold}) :-
    term_json(Id, IdString),
    atom_json(Layer, LayerString),
    atom_json(Activation, ActivationString).

edge_json(edge(From, To, Weight),
          _{from: FromString, to: ToString, weight: Weight}) :-
    term_json(From, FromString),
    term_json(To, ToString).

recurrent_json(recurrent(From, To),
               _{from: FromString, to: ToString}) :-
    term_json(From, FromString),
    term_json(To, ToString).

trace_json(trace(Neuron, Clause, File, Line),
           _{neuron: NeuronString,
             clause: Clause,
             file: FileString,
             line: Line}) :-
    term_json(Neuron, NeuronString),
    atom_json(File, FileString).
