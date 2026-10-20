:- module(prolog2ann_translate, [translate/3]).

:- use_module(library(lists)).

%! translate(+GroundClauses, +Atoms, -Network) is det.
%
% Convert grounded clauses into a deterministic list-based network model.
translate(GroundClauses, Atoms, network(Atoms, Rules, Strata, Traces)) :-
    findall(rule(Head, Positive, Negative, Stratum),
            member(ground_clause(Head, Positive, Negative, _, _, _, _, Stratum),
                   GroundClauses),
            Rules0),
    sort(Rules0, Rules),
    findall(Stratum, member(rule(_, _, _, Stratum), Rules), Strata0),
    sort(Strata0, Strata),
    findall(trace(hidden(Id), Id, File, Line),
            ( nth1(Id, GroundClauses, ground_clause(_, _, _, _, _, File, Line, _)) ),
            Traces).
