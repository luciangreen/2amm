:- module(prolog2ann_ground, [ground_program/5, read_domain/2]).

:- use_module(library(lists)).

%! read_domain(+File, -Values) is det.
%
% Read finite values from domain/2 and range/3 declarations.
read_domain(File, Values) :-
    setup_call_cleanup(
        open(File, read, Stream, [encoding(utf8)]),
        read_domain_terms(Stream, Terms),
        close(Stream)),
    findall(Value,
            ( member(Term, Terms),
              ( Term = domain(_, Items), member(Value, Items)
              ; Term = range(_, Low, High), integer(Low), integer(High),
                Low =< High, between(Low, High, Value)
              )),
            Values0),
    (   forall(member(Term, Terms), valid_domain_term(Term))
    ->  sort(Values0, Values)
    ;   throw(error(domain_error(finite_domain_declaration, File), _))
    ).

%! read_domain_terms(+Stream, -Terms) is det.
%
% Read all declarations from a domain file.
read_domain_terms(Stream, Terms) :-
    read_term(Stream, Term, [syntax_errors(error)]),
    ( Term == end_of_file -> Terms = []
    ; Terms = [Term|Rest], read_domain_terms(Stream, Rest)
    ).

%! valid_domain_term(+Term) is semidet.
%
% Validate one finite domain/2 or ascending integer range/3 declaration.
valid_domain_term(domain(_, Values)) :-
    is_list(Values),
    maplist(finite_value, Values).
valid_domain_term(range(_, Low, High)) :-
    integer(Low),
    integer(High),
    Low =< High.

%! finite_value(+Value) is semidet.
%
% Domain members must be atomic.
finite_value(Value) :-
    atomic(Value).

%! ground_program(+Normalised, +DomainValues, -GroundClauses, +Limit, -Atoms) is det.
%
% Instantiate variables over the finite universe, pre-evaluate supported
% built-ins, and enforce the Herbrand-base size limit.
ground_program(Normalised, DomainValues, GroundClauses, Limit, Atoms) :-
    source_values(Normalised, SourceValues),
    append(DomainValues, SourceValues, Values),
    sort(Values, Universe),
    require_finite_universe(Normalised, Universe),
    findall(Ground,
            ( member(Clause, Normalised),
              ground_clause(Clause, Universe, Ground)
            ),
            GroundClauses),
    findall(Atom,
            ( member(ground_clause(H, Pos, Neg, _, _, _, _, _), GroundClauses),
              ( Atom = H ; member(Atom, Pos) ; member(Atom, Neg) )
            ),
            Atoms0),
    sort(Atoms0, Atoms),
    length(Atoms, Size),
    (   Size =< Limit
    ->  true
    ;   throw(error(herbrand_base_limit(Size, Limit), _))
    ).

%! require_finite_universe(+Clauses, +Universe) is det.
%
% Reject variable-bearing clauses when no finite grounding values exist.
require_finite_universe(Clauses, []) :-
    member(ground_clause(Head, Positive, Negative, Builtins, _, _, _, _),
           Clauses),
    term_variables(Head-Positive-Negative-Builtins, [_|_]),
    !,
    throw(error(finite_domain_required, _)).
require_finite_universe(_, _).

%! source_values(+Clauses, -Values) is det.
%
% Collect atomic constants used in clauses and built-in expressions.
source_values(Clauses, Values) :-
    findall(Value,
            ( member(ground_clause(H, Pos, Neg, Builtins, _, _, _, _), Clauses),
              ( sub_term(Value, H)
              ; member(Goal, Pos), sub_term(Value, Goal)
              ; member(Goal, Neg), sub_term(Value, Goal)
              ; member(Goal, Builtins), sub_term(Value, Goal)
              ),
              atomic(Value)
            ),
            Values).

%! ground_clause(+Clause, +Universe, -GroundClause) is nondet.
%
% Instantiate the clause variables and retain only assignments satisfying
% every pre-evaluated built-in.
ground_clause(ground_clause(Head, Positive, Negative, Builtins, Names, File,
                            Line, Stratum),
              Universe,
              ground_clause(GHead, GPositive, GNegative, [], Names, File,
                            Line, Stratum)) :-
    copy_term(Head-Positive-Negative-Builtins,
              GHead-GPositive-GNegative-GBuiltins),
    term_variables(GHead-GPositive-GNegative-GBuiltins, Variables),
    assign_variables(Variables, Universe),
    maplist(evaluate_builtin, GBuiltins).

%! assign_variables(+Variables, +Universe) is nondet.
%
% Bind each variable to one member of the finite universe.
assign_variables([], _).
assign_variables([Variable|Rest], Universe) :-
    member(Value, Universe),
    Variable = Value,
    assign_variables(Rest, Universe).

%! evaluate_builtin(+Goal) is semidet.
%
% Evaluate a supported comparison, unification, or arithmetic goal.
evaluate_builtin(true) :- !.
evaluate_builtin(fail) :- !, fail.
evaluate_builtin(false) :- !, fail.
evaluate_builtin(A < B) :- !, integer_expression(A, X), integer_expression(B, Y), X < Y.
evaluate_builtin(A > B) :- !, integer_expression(A, X), integer_expression(B, Y), X > Y.
evaluate_builtin(A =< B) :- !, integer_expression(A, X), integer_expression(B, Y), X =< Y.
evaluate_builtin(A >= B) :- !, integer_expression(A, X), integer_expression(B, Y), X >= Y.
evaluate_builtin(A =:= B) :- !, integer_expression(A, X), integer_expression(B, Y), X =:= Y.
evaluate_builtin(A =\= B) :- !, integer_expression(A, X), integer_expression(B, Y), X =\= Y.
evaluate_builtin(A = B) :- !, A = B.
evaluate_builtin(A \= B) :- !, A \= B.
evaluate_builtin(Variable is Expression) :-
    integer_expression(Expression, Value),
    Variable = Value.

%! integer_expression(+Expression, -Value) is semidet.
%
% Evaluate an integer expression using the supported arithmetic operators.
integer_expression(Expression, Value) :-
    (   integer(Expression)
    ->  Value = Expression
    ;   compound(Expression),
        Expression =.. [Operator, A, B],
        integer_expression(A, X),
        integer_expression(B, Y),
        arithmetic_result(Operator, X, Y, Value)
    ).

%! arithmetic_result(+Operator, +Left, +Right, -Result) is semidet.
%
% Apply one supported binary integer arithmetic operator.
arithmetic_result(+, A, B, Result) :- Result is A + B.
arithmetic_result(-, A, B, Result) :- Result is A - B.
arithmetic_result(*, A, B, Result) :- Result is A * B.
arithmetic_result(//, A, B, Result) :- B =\= 0, Result is A // B.
arithmetic_result(mod, A, B, Result) :- B =\= 0, Result is A mod B.
arithmetic_result(rem, A, B, Result) :- B =\= 0, Result is A rem B.
