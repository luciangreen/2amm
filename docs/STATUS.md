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
| FR-11 | Not implemented — program extraction |
| FR-12 | Partial — emits basic source trace facts; no complete neuron-to-clause traceability yet |
| FR-13 | Not implemented — JSON export |

## Remaining work

1. Correct and complete the five-stage acceptance behavior: typed domain
   inference, integer binding/range semantics, full unsupported syntax
   diagnostics, and exact stratification diagnostics.
2. Replace symbolic ground-rule execution with the explicit weighted
   input/hidden/output neuron model, recurrent links, and complete trace map.
3. Add JSON export and CLI support for JSON output. Source-equivalence checking
   is implemented for the supported subset; its finite universe is inferred
   from the network atom base and source constants.
4. Verify the sigmoid/CILP formula against the cited paper and implement
   sigmoid/tanh modes and training only after recording the exact assumptions.
5. Implement step-network extraction.
6. Add the remaining acceptance examples, round-trip and training tests,
   randomized property tests, CI, PlDoc coverage, and release/pack metadata
   checks before claiming M1–M6 complete.

## Tests and examples to run now

```sh
swipl -q -s test/run_tests.pl
mkdir -p build
swipl bin/prolog2ann.pl convert examples/ancestor.pl \
  --domain examples/ancestor_domain.pl --mode step \
  --out build/net_ancestor.pl --module net_ancestor
swipl bin/prolog2ann.pl query build/net_ancestor.pl "ancestor(ann, dee)"
swipl bin/prolog2ann.pl verify examples/ancestor.pl build/net_ancestor.pl
```

To inspect a deliberately limited runtime run, convert with
`--step-limit 1`, then call the generated module's `ann_run/3`. A run that
does not converge within that limit reports `Reached = false`; `ann_query/2`
and `ann_query_all/2` raise `error(no_fixpoint(Steps), _)` for such a run.

The full requirements' acceptance tests must not be treated as passing merely
because these current tests pass.
