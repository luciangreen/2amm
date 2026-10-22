# Design decisions

## Current finite universe

All variables are grounded over the sorted union of atomic constants found in
the source and values declared with `domain/2` or `range/3`. The `Type` and
`Name` arguments are retained as declaration labels but are not associated
with predicate positions yet. This is the simplest deterministic finite
universe until typed-domain inference is specified.

## Unsupported terms

Nested compound and list arguments are rejected rather than partially
grounded. The v1 brief allows those terms only with a configured depth/length
bound, and no such bound is implemented yet.

Supported arithmetic expressions are limited to integer literals, variables,
and `+`, `-`, `*`, `//`, `mod`, and `rem`. Other expression shapes are rejected
during parsing with the source location instead of being treated as a failed
grounding assignment.

## Verification universe

`ann_verify/3` does not take a domain file. It derives values from the network's
ground atom base and combines them with constants in the source before
grounding. This checks the source against the exact finite base represented by
the generated network without requiring the original domain file.

## Sigmoid weight bound

Sigmoid mode is not enabled until its bound can be attributed accurately.
Under the logistic activation and the brief's single-neuron threshold
\((m-\tfrac12)W\), the AND-neuron margin is \(W/2\), so achieving error at most
\(\epsilon\) requires \(W \ge 2\ln((1-\epsilon)/\epsilon)\). This is a derived
saturation bound under those assumptions, not a verified formula from
d'Avila Garcez and Zaverucha (1999); it does not establish a bound for an
entire recurrent network with OR aggregation.
