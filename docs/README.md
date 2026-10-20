# Using prolog2ann

## Requirements and quickstart

- SWI-Prolog 9.x
- Run commands from the repository root. The CLI adds this checkout's
  `prolog/` directory to SWI-Prolog's library path.

```sh
mkdir -p build
swipl bin/prolog2ann.pl convert examples/ancestor.pl \
  --domain examples/ancestor_domain.pl --mode step \
  --out build/net_ancestor.pl --module net_ancestor
swipl bin/prolog2ann.pl query build/net_ancestor.pl "ancestor(ann, dee)"
```

The query command prints `ancestor(ann,dee): true`; a ground atom not in the
least model prints `false`. The generated module uses the packaged
`prolog2ann/runtime` library, but does not load or need the source program.

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
- Source locations on parse-time unsupported-construct errors.
- Optional runtime fixpoint step limit, set at conversion time with
  `--step-limit N` (or `step_limit(N)` in `convert_file/3` options). If omitted,
  each stratum uses the default Herbrand-base size + 1. `ann_run/3` reports
  `ReachedFixpoint = false` when the configured limit is reached, and query
  predicates raise `error(no_fixpoint(Steps), _)`.

`--limit N` is a separate conversion-time cap on the grounded Herbrand base
(default 10,000); it is not a runtime step limit. The CLI supports:

- `convert SOURCE [--domain FILE] [--mode step] [--limit N] [--step-limit N]`
  `--out FILE [--module NAME]`
- `query NETWORK.pl "ground_goal"`

The CLI also recognizes `verify SOURCE NETWORK.pl`, but verification is a
placeholder and currently raises `error(not_implemented(verify), _)`.

The generated module exports `ann_query/2`, `ann_query_all/2`, and
`ann_run/3`, along with the inspectable neuron, edge, recurrent-link, and trace
facts. The library entry point exports `convert_file/3`, `convert_clauses/3`,
and the currently unimplemented `ann_verify/3` stub.

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
converter. Nested compound/list terms, cut, dynamic database operations,
I/O, `findall`/`bagof`/`setof`, and unsupported system built-ins are rejected.
Only exact step mode is implemented. The emitted runtime computes the same
stratified least-model closure symbolically from ground rules; the full
explicit weighted-neuron encoding in `pr1.txt` is not finished.

Sigmoid/tanh activation, the CILP weight-bound implementation, training,
extraction, JSON export, full `ann_verify/3`, and the complete acceptance and
random-property suites are not implemented. Consult [`STATUS.md`](STATUS.md)
for the requirement-by-requirement list.

## Tests

Run the PlUnit suite from the repository root:

```sh
swipl -q -s test/run_tests.pl
```

The current suite exercises parsing, cut rejection with a source line,
negative-cycle detection, the grounding-size limit, stratified negation,
mutual recursion over a bounded integer range, emitted-module queries, and
conversion output. It also checks the optional runtime step limit.

Run the ancestor example end to end using the quickstart. To impose a runtime
limit, add `--step-limit 1` to `convert`; then call the generated module's
`ann_run(Atoms, Steps, Reached)` to inspect whether its fixpoint was reached.
More acceptance programs from `pr1.txt` (including cyclic reachability, XOR,
training, extraction, JSON export, and randomized equivalence) remain to be
added.
