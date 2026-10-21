bit(0).
bit(1).

same(X, Y) :-
    bit(X),
    bit(Y),
    X = Y.

xor(X, Y) :-
    bit(X),
    bit(Y),
    \+ same(X, Y).
