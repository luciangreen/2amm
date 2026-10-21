edge(a, b).
edge(b, c).
edge(c, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
