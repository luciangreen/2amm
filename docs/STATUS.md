# Implementation status against `pr1.txt`

This repository currently contains an early, runnable step-mode slice. It does
not yet satisfy the v1 acceptance criteria in full.

| Requirement | Status |
| --- | --- |
| FR-1 | Partial — `.pl` source and optional `domain/2`/`range/3` files; currently one global universe |
| FR-2 | Partial — cut, dynamic database, I/O, collection predicates, unsupported system calls, and nested terms are rejected |
| FR-3 | Implemented for predicate dependency stratification; reports predicate indicators in a negative cycle |
| FR-4 | Implemented — counts grounded head/body atoms; default limit 10,000 |
| FR-5 | Partial — exact step mode only |
| FR-6 | Partial — emits a module independent of source, with a generic package runtime dependency |
| FR-7 | Implemented in emitted modules for ground goals |
| FR-8 | Implemented in emitted modules for matching active atoms |
| FR-9 | Implemented for the supported subset — fixpoint evaluation, default and configurable per-network step limits (`--step-limit`), and source/network least-model comparison with `ann_verify/3` |
| FR-10 | Not implemented — sigmoid backpropagation |
| FR-11 | Implemented for step-mode `network/7` terms and loaded generated modules; extracts ground rules and supports round-trip conversion |
| FR-12 | Implemented for the step-mode representation — traces input, hidden, and output neurons to represented ground clauses, with source file and line |
| FR-13 | Implemented for the current step-mode schema — exports atoms, neurons, weighted edges, recurrent links, and traces via `--json` or `ann_export_json/2` |

## Remaining work

1. Finish typed-domain inference and variable binding/range semantics; the
   current grounding universe is global. Implement bounded lists/compound terms
   and complete the required unsupported-syntax diagnostics.
2. Replace symbolic ground-rule execution with evaluation of the explicit
   weighted input/hidden/output neuron model and recurrent links. The JSON
   reports the network facts but does not implement this runtime change.
3. Verify the sigmoid/CILP formula against the cited paper before implementing
   sigmoid/tanh modes and training; record the exact assumptions.
4. Add sigmoid/training tests after implementing M4. Add CI, complete PlDoc
   coverage, and release/pack metadata checks before claiming M1–M6 complete.

## Tests and examples to run now

```sh
swipl -q -s test/run_tests.pl
mkdir -p build
swipl bin/prolog2ann.pl convert examples/ancestor.pl \
  --domain examples/ancestor_domain.pl --mode step \
  --out build/net_ancestor.pl --module net_ancestor \
  --json build/net_ancestor.json
swipl bin/prolog2ann.pl query build/net_ancestor.pl "ancestor(ann, dee)"
swipl bin/prolog2ann.pl verify examples/ancestor.pl build/net_ancestor.pl
```

To inspect a deliberately limited runtime run, convert with
`--step-limit 1`, then call the generated module's `ann_run/3`. A run that
does not converge within that limit reports `Reached = false`; `ann_query/2`
and `ann_query_all/2` raise `error(no_fixpoint(Steps), _)` for such a run.

The PlUnit suite also covers parser diagnostics, grounding limits, weighted
translation, input/hidden/output source traces, negation, XOR, mutual recursion
over an integer range, JSON structure, step limits, equivalence/mismatch
reporting, and extraction round trips for positive recursion, stratified
negation, generated modules, and cyclic reachability. The cyclic example checks
recursive self-reachability and that fixpoint evaluation completes within the
default Herbrand-base-derived bound.
Use `swipl -q -s test/run_tests.pl` to run all tests. JSON export is step-mode
inspection output; sigmoid training is not yet implemented. The suite now
includes 200 deterministic randomized least-model equivalence checks.
Extraction returns represented ground rules only: it does not
reconstruct the source's variable names, comments, source order, or domain
declarations.

The full requirements' acceptance tests must not be treated as passing merely
because these current tests pass.

## Coverage update

The PlUnit suite now includes full least-model equivalence checks for each
supported acceptance example (`ancestor`, `reach`, `even_odd`, `xor`, and
`flies`) and rejects the checked-in `win.pl` non-stratified program. Run the
suite with `swipl -q -s test/run_tests.pl`; see [`README.md`](README.md) for
copy/paste CLI commands for the supported examples.

These checks extend the current regression coverage; they do not complete the
remaining v1 requirements below. The main implementation milestones still
outstanding are typed finite domains and bounded compound terms, execution of
the explicit weighted network, verified sigmoid/tanh support and training,
CI, and release readiness.

## Latest implementation update

Step-mode program extraction is now available through `ann_extract/2` for
in-memory `network/7` terms and loaded generated modules. It returns ground
clauses from the network rule facts and is tested by re-converting the result,
including a stratified-negation case. This is not recovery of original source
text and does not change the symbolic ground-rule runtime.

The finite-domain XOR acceptance example is covered by an automated test for
the four truth-table outcomes and least-model equivalence. This adds an
acceptance example; it does not add sigmoid-mode support or weighted-neuron
execution.

Source trace facts now cover each input and output neuron for every ground
clause where its atom occurs, as well as each hidden neuron for its clause.
These trace clause identifiers refer to the grounded network clauses; the
original variable-bearing source clauses are not reconstructed.

The test suite now performs deterministic property-style checking of 200
generated finite Datalog programs. The generator stays within six unary
predicates and five constants and includes recursion and stratified negation;
each generated module is compared against the source program's least model.
This completes the random-program count in the current acceptance criteria,
but does not replace the still-pending typed-domain, weighted-runtime, sigmoid,
training, CI, or release work listed above.
