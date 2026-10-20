even(0).
even(N) :- odd(M), N is M + 1.
odd(N) :- even(M), N is M + 1.
