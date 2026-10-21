# Using prolog2ann

## Requirements and quickstart

- SWI-Prolog 9.x
- Run commands from the repository root. The CLI adds this checkout's
  `prolog/` directory to SWI-Prolog's library path.

```sh
mkdir -p build
swipl bin/prolog2ann.pl convert examples/ancestor.pl \
  --domain examples/ancestor_domain.pl --mode step \
  --out build/net_ancestor.pl --module net_ancestor \
  --json build/net_ancestor.json
swipl bin/prolog2ann.pl query build/net_ancestor.pl "ancestor(ann, dee)"
swipl bin/prolog2ann.pl verify examples/ancestor.pl build/net_ancestor.pl
```

The query command prints `ancestor(ann,dee): true`; a ground atom not in the
least model prints `false`. Verification prints a success message when the
source and generated network have the same least model. Otherwise it reports
atoms missing from the network and unexpected network atoms, and exits with
status 1. The generated module uses the packaged `prolog2ann/runtime` library,
but does not load or need the source program.

The XOR acceptance example exercises finite grounding, equality, stratified
negation, pattern queries, and source/network verification:

```sh
swipl bin/prolog2ann.pl convert examples/xor.pl --mode step \
  --out build/net_xor.pl --module net_xor
swipl bin/prolog2ann.pl query build/net_xor.pl "xor(0, 1)"
swipl bin/prolog2ann.pl query build/net_xor.pl "xor(0, 0)"
swipl bin/prolog2ann.pl verify examples/xor.pl build/net_xor.pl
```

The first query returns `true`, the second returns `false`, and verification
checks the complete finite least model.

The cyclic reachability example can be converted and checked independently:

```sh
swipl bin/prolog2ann.pl convert examples/reach.pl --mode step \
  --out build/net_reach.pl --module net_reach
swipl bin/prolog2ann.pl query build/net_reach.pl "reach(a, a)"
swipl bin/prolog2ann.pl verify examples/reach.pl build/net_reach.pl
```

The graph contains a cycle, so the least model includes `reach(a,a)`,
`reach(b,b)`, and `reach(c,c)` as well as the paths between distinct vertices.

For an independent installation of an emitted module, install `prolog2ann` as
a SWI-Prolog pack or include the package's `prolog/` directory on SWI-Prolog's
library path. Generated modules export `ann_query/2`, `ann_query_all/2`, and
`ann_run/3`.

## Supported behavior

- Facts and definite clauses with variables ranging over a finite set of
  constants.
- Direct and mutual recursion, conjunction, and disjunction (split into
  separate clauses).
- Stratified negation as failure; negative dependency cycles are rejected and
  reported with the involved predicate indicators.
- Finite integer domains declared by `range(Name, Low, High).`; supported
  comparisons and bounded `is/2` arithmetic are evaluated before translation.
- Optional domain declarations in the form
  `domain(Type, [constant, ...]).`; all declared values currently share one
  global grounding universe.
- A configurable maximum Herbrand-base size (default 10,000).
- A step-mode Prolog network with ground queries, pattern queries, and
  fixpoint step reporting. The default per-stratum limit is base size + 1;
  unsuccessful query runs raise `error(no_fixpoint(Steps), _)`.
- Inspectable input, hidden, and output neuron facts, weighted edges,
  recurrent links, and source traces mapping each neuron to every represented
  ground clause containing its atom; optional JSON export of this current
  step-mode representation.
- Source locations on parse-time unsupported-construct errors.
- Source-equivalence verification for a `network/7` term or a loaded generated
  module, returning `equivalent` or `mismatch(Missing, Unexpected)`.
- Step-mode extraction via `ann_extract/2`, reconstructing the network's
  represented ground clauses from either a `network/7` term or a loaded
  generated module.
- Optional runtime fixpoint step limit, set at conversion time with
  `--step-limit N` (or `step_limit(N)` in `convert_file/3` options). If omitted,
  each stratum uses the default Herbrand-base size + 1. `ann_run/3` reports
  `ReachedFixpoint = false` when the configured limit is reached, and query
  predicates raise `error(no_fixpoint(Steps), _)`.

`--limit N` is a separate conversion-time cap on the grounded Herbrand base
(default 10,000); it is not a runtime step limit. The CLI supports:

- `convert SOURCE [--domain FILE] [--mode step] [--limit N] [--step-limit N]`
  `--out FILE [--module NAME] [--json FILE]`
- `query NETWORK.pl "ground_goal"`
- `verify SOURCE NETWORK.pl`

The `--json FILE` option writes a JSON object containing `mode`, `atoms`,
`neurons` (IDs, layers, activations, and thresholds), `edges` (source, target,
and weight), `recurrent` links, and source `traces`. The library also exports
`ann_export_json(+File, +Network)` for exporting a network returned by
`convert_file/3` or `convert_clauses/3`. JSON currently describes the
step-mode representation; it does not imply support for sigmoid training.

Verification uses the finite universe represented by the network's atom base,
combined with constants in the source program. The library API does not accept
a separate domain file for verification.

The generated module exports `ann_query/2`, `ann_query_all/2`, and
`ann_run/3`, along with the inspectable neuron, edge, recurrent-link, and trace
facts. The library entry point exports `convert_file/3`, `convert_clauses/3`,
`ann_verify/3`, `ann_export_json/2`, and `ann_extract/2`.

`ann_extract(Network, Clauses)` returns ground facts and rules. The extracted
program preserves represented positive and stratified-negative rules, so it can
be passed to `convert_clauses/3` for round-trip checks. Extraction cannot recover
the original variables, clause order, comments, source locations, domain
declarations, or source formatting. `ann_extract(GeneratedModule, Clauses)` also
accepts a loaded generated step-mode module.

Example bounded input:

```prolog
domain(person, [ann, bob]).
range(n, 0, 4).
```

The domain file accepts `domain/2` and `range/3` facts. Variable types are not
inferred from the type name yet: each variable ranges over the union of all
domain and source constants.

## Current limitations

This is an in-progress subset of `pr1.txt`, not the v1 acceptance-complete
converter. The current finite universe is the union of source constants and
values from `domain/2` and `range/3`; type labels are not used to constrain
individual variables or predicate positions. Nested compound/list terms,
cut, dynamic database operations, I/O, `findall`/`bagof`/`setof`, and unsupported
system built-ins are rejected. Only exact step mode is implemented. Although
translation emits inspectable neuron, edge, and recurrent-link facts, runtime
evaluation computes stratified least-model closure from retained symbolic
ground rules rather than evaluating those weighted facts.

Trace facts cover input and output neurons for each ground clause in which their
atom appears, and hidden neurons for their corresponding ground clause. Clause
IDs identify the clauses in the grounded network, not original variable-bearing
source clauses. `ann_extract/2` and JSON export are implemented for the current
step-mode schema; extraction returns represented ground rules, not original
source text. Sigmoid/tanh activation, a verified CILP weight-bound implementation,
and training are not implemented. Verification covers least-model agreement
only for programs in the supported finite-domain subset.
Consult
[`STATUS.md`](STATUS.md) for the requirement-by-requirement list.

## Tests

Run the PlUnit suite from the repository root:

```sh
swipl -q -s test/run_tests.pl
```

The current suite exercises parsing, cut rejection with a source line,
negative-cycle detection, the grounding-size limit, stratified negation,
mutual recursion over a bounded integer range, cyclic reachability through a
fixpoint (including self-reachability), emitted-module queries and conversion
output, JSON export and its network fields, the optional runtime step limit,
input/hidden/output neuron trace facts, source/network equivalence and mismatch
reporting, and extraction round trips for recursion, stratified negation, and
generated modules, plus XOR equivalence and query results. Run all current
PlUnit tests with the command above. The
ancestor quickstart exercises
conversion, generated-module querying, source/network verification, and JSON
generation; the `flies`, `even_odd`, and `reach` examples exercise stratified
negation, bounded mutual recursion, and cyclic recursive closure respectively.
The `xor` example exercises stratified negation and verifies all four input
pairs through the finite least model.

Run the ancestor example end to end using the quickstart. To impose a runtime
limit, add `--step-limit 1` to `convert`; then call the generated module's
`ann_run(Atoms, Steps, Reached)` to inspect whether its fixpoint was reached.
The `verify` command accepts the source file and generated network file in
that order. The current extraction API can be exercised from the Prolog top
level after loading `prolog/prolog2ann.pl` and generating or converting a
network: call `prolog2ann:ann_extract(Network, Clauses)` and then
`prolog2ann:convert_clauses(Clauses, [], RoundTripNetwork)`.
Additional acceptance coverage, sigmoid training, and randomized equivalence
remain to be added. See
[`STATUS.md`](STATUS.md) for the current requirement-by-requirement status and
the remaining milestones.
