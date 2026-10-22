:- module(prolog2ann_runtime,
          [ ann_query/3,
            ann_query_all/3,
            run_network/4
          ]).

:- use_module(library(lists)).

%! ann_query(+Module, +GroundGoal, -Truth) is det.
%
% Query a generated network for a ground atom; Truth is true or false.
ann_query(Module, Goal, Truth) :-
    ( ground(Goal) -> true ; throw(error(instantiation_error, _)) ),
    run_network(Module, Atoms, Steps, Reached),
    ( Reached == true -> true ; throw(error(no_fixpoint(Steps), _)) ),
    ( memberchk(Goal, Atoms) -> Truth = true ; Truth = false ).

%! ann_query_all(+Module, +Pattern, -Solutions) is det.
%
% Return all active ground atoms matching Pattern, in standard order.
ann_query_all(Module, Pattern, Solutions) :-
    run_network(Module, Atoms, Steps, Reached),
    ( Reached == true -> true ; throw(error(no_fixpoint(Steps), _)) ),
    findall(Atom,
            ( member(Atom, Atoms),
              copy_term(Pattern, PatternCopy),
              PatternCopy = Atom
            ),
            Solutions0),
    sort(Solutions0, Solutions).

%! run_network(+Module, -Atoms, -Steps, -ReachedFixpoint) is det.
%
% Evaluate strata in order; each positive stratum runs to a least fixpoint.
% Steps counts successful closure rounds and the final no-change round.
run_network(Module, Atoms, Steps, Reached) :-
    module_facts(Module, Atom, network_atom(Atom), AtomList0),
    sort(AtomList0, Base),
    module_facts(Module, Stratum, network_stratum(Stratum), Strata0),
    sort(Strata0, Strata),
    module_step_limit(Module, Base, Limit),
    run_strata(Strata, Module, [], Base, Limit, Model, Steps, Reached),
    Atoms = Model.

%! module_facts(+Module, ?Template, +Goal, -Facts) is det.
%
% Collect facts from a generated module, treating an absent predicate as empty.
module_facts(Module, Template, Goal, Facts) :-
    functor(Goal, Name, Arity),
    (   current_predicate(Module:Name/Arity)
    ->  findall(Template, Module:Goal, Facts)
    ;   Facts = []
    ).

%! module_step_limit(+Module, +Base, -Limit) is det.
%
% Use the generated module's configured limit or derive one from its atom base.
module_step_limit(Module, Base, Limit) :-
    (   current_predicate(Module:network_step_limit/1),
        Module:network_step_limit(Configured)
    ->  Limit = Configured
    ;   length(Base, BaseSize),
        Limit is BaseSize + 1
    ).

%! run_strata(+Strata, +Module, +Lower, +Base, +Limit, -Model,
%!            -Steps, -Reached) is det.
%
% Close each stratum in order and stop if a configured limit is exhausted.
run_strata([], _, Model, _, _, Model, 0, true).
run_strata([Stratum|Rest], Module, Lower, Base, Limit, Model, Steps, Reached) :-
    close_stratum(Module, Stratum, Lower, Base, Limit, Closed, Used, Reached0),
    (   Reached0 == true
    ->  run_strata(Rest, Module, Closed, Base, Limit, Model, Remaining, Reached),
        Steps is Used + Remaining
    ;   Model = Closed,
        Steps = Used,
        Reached = false
    ).

%! close_stratum(+Module, +Stratum, +Current, +Base, +Limit,
%!               -Model, -Steps, -Reached) is det.
%
% Compute one stratum's closure using the lower-stratum model as input.
close_stratum(Module, Stratum, Current, Base, Limit, Model, Steps, Reached) :-
    close_round(1, Module, Stratum, Current, Base, Limit, Model, Steps, Reached).

%! close_round(+Step, +Module, +Stratum, +Current, +Base, +Limit,
%!             -Model, -Steps, -Reached) is det.
%
% Apply one immediate-consequence round and detect stability or limit exhaustion.
close_round(Step, Module, Stratum, Current, Base, Limit, Model, Steps, Reached) :-
    applicable_heads(Module, Stratum, Current, Heads),
    append(Current, Heads, Combined),
    sort(Combined, Next),
    (   Next == Current
    ->  Model = Current,
        Steps = Step,
        Reached = true
    ;   Step >= Limit
    ->  Model = Next,
        Steps = Step,
        Reached = false
    ;   NextStep is Step + 1,
        close_round(NextStep, Module, Stratum, Next, Base, Limit,
                    Model, Steps, Reached)
    ).

%! applicable_heads(+Module, +Stratum, +Current, -Heads) is det.
%
% Collect heads whose positive and negative body atoms match the current model.
applicable_heads(Module, Stratum, Current, Heads) :-
    findall(Head,
            ( Module:network_rule(Head, Positive, Negative, Stratum),
              all_members(Positive, Current),
              no_members(Negative, Current)
            ),
            Heads0),
    sort(Heads0, Heads).

%! all_members(+Items, +Set) is semidet.
%
% Succeed when every item occurs in the supplied set.
all_members([], _).
all_members([Atom|Rest], Atoms) :-
    memberchk(Atom, Atoms),
    all_members(Rest, Atoms).

%! no_members(+Items, +Set) is semidet.
%
% Succeed when none of the items occurs in the supplied set.
no_members([], _).
no_members([Atom|Rest], Atoms) :-
    \+ memberchk(Atom, Atoms),
    no_members(Rest, Atoms).
