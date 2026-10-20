bird(tweety).
bird(polly).
bird(pingu).
penguin(pingu).

flies(X) :- bird(X), \+ penguin(X).
