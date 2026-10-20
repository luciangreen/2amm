move(a, b).
move(b, a).

win(X) :- move(X, Y), \+ win(Y).
