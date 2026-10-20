parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(ann, eli).
parent(eli, fay).
parent(fay, gus).
parent(gus, hal).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
