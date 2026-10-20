# Using prolog2ann

## Requirements and quickstart

- SWI-Prolog 9.x
- Run commands from the repository root. The CLI adds this checkout's
  `prolog/` directory to SWI-Prolog's library path.

```sh
mkdir -p build
swipl bin/prolog2ann.pl convert examples/ancestor.pl \
  --domain examples/ancestor_domain.pl \
  --mode step --out build/net_ancestor.pl --module net_ancestor
swipl bin/prolog2ann.pl query build/net_ancestor.pl "ancestor(ann, dee)"
```

The query command prints `ancestor(ann,dee): true`; a ground atom not in the
least model prints `false`. The generated module uses the packaged
`prolog2ann/runtime` library, but does not load or need the source program.

The converter accepts `--limit N` to cap the grounded Herbrand base (default
10,000 atoms) and `--steps N` to set the maximum closure rounds for each
stratum in the emitted runtime (default: base size + 1). Both values must be
positive integers. For example, use `--steps 20` before `--out` to generate a
network with a per-stratum limit of 20. If a stratum has not reached a fixpoint
within its limit, `ann_run/3` returns `Reached = false` and query predicates
raise `error(no_fixpoint(Steps), _)`.

The CLI also supports `--module NAME` to choose the generated module name.
`convert` supports only `--mode step`; other modes are rejected.

For an independent installation of an emitted module, install `prolog2ann` as
a SWI-Prolog pack or include the package's `prolog/` directory on SWI-Prolog's
library path. Generated modules export `ann_query/2`, `ann_query_all/2`, and
`ann_run/3`. `ann_query/2` requires a ground goal and returns true or false;
`ann_query_all/2` accepts a pattern and returns its active ground instances in
standard order; `ann_run/3` returns the active atoms, number of rounds, and
whether every stratum reached a fixpoint.

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

The library API exports `convert_file/3`, `convert_clauses/3`, and the
`ann_verify/3` placeholder. `convert_file/3` accepts `domain(File)`, `out(File)`,
`module(Name)`, `mode(step)`, `limit(MaxAtoms)`, and `step_limit(MaxRounds)`.
`convert_clauses/3` accepts `domain_values(Values)`, `mode(step)`, and
`limit(MaxAtoms)`. The limits must be positive integers.

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
conversion output, including a configured runtime step limit.

Run the current checks from the repository root:

```sh
# PlUnit regression suite
swipl -q -s test/run_tests.pl

# Recursive ancestor conversion and ground query
mkdir -p build
swipl bin/prolog2ann.pl convert examples/ancestor.pl \
  --domain examples/ancestor_domain.pl --mode step \
  --out build/net_ancestor.pl --module net_ancestor
swipl bin/prolog2ann.pl query build/net_ancestor.pl "ancestor(ann, dee)"

# Mutual recursion over the supplied integer range
swipl bin/prolog2ann.pl convert examples/even_odd.pl \
  --domain examples/even_odd_domain.pl --mode step \
  --out build/net_even_odd.pl --module net_even_odd
swipl bin/prolog2ann.pl query build/net_even_odd.pl "even(4)"

# Stratified negation and a bounded runtime
swipl bin/prolog2ann.pl convert examples/flies.pl --mode step \
  --steps 20 --out build/net_flies.pl --module net_flies
swipl bin/prolog2ann.pl query build/net_flies.pl "flies(tweety)"
```

The PlUnit tests also cover expected rejections using `examples/cut.pl` and
`examples/win.pl`. The broader acceptance programs (cyclic reachability, XOR,
sigmoid training, extraction, JSON, and randomized equivalence) have not yet
been implemented; see [`STATUS.md`](STATUS.md) for the remaining work.
