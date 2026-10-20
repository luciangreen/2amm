# Design

Conversion is currently split into independently loadable SWI-Prolog modules:

1. `parse.pl` reads clauses and retains variable names, file names, and source
   lines. It rejects unsupported built-ins and nested compound arguments.
2. `normalise.pl` expands disjunctions, separates positive, negative, and
   built-in literals, and checks the predicate dependency graph for
   stratification.
3. `ground.pl` combines source constants with optional domain values, grounds
   variables over the finite universe, evaluates supported comparisons and
   arithmetic, and enforces the atom limit.
4. `translate.pl` builds a deterministic network model from the ground
   clauses, including input/output/hidden neuron facts, weighted edges,
   recurrent links, and source trace facts.
5. `emit.pl` serializes a Prolog module. `runtime.pl` evaluates each stratum to
   a least fixpoint and provides query APIs.

The initial implementation prioritizes exact, finite step-mode answers. The
output includes the explicit step-mode neuron and edge representation, while
the runtime currently computes closure from retained symbolic ground rules
rather than evaluating those edges. The output is independent of the source
program but imports the generic runtime library.

The current grounding universe is global rather than type-directed. A
variable-free program can still be converted without a domain file; a program
with variables needs source constants or explicit finite domain values.
