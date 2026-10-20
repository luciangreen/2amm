# prolog2ann

`prolog2ann` is a pure SWI-Prolog converter for finite-domain Datalog-style
programs. It grounds the supported program subset and emits a Prolog module
whose step-mode fixpoint implements its least model. See
[`docs/README.md`](docs/README.md) for the feature matrix, limitations,
quickstart, and test commands, and [`docs/STATUS.md`](docs/STATUS.md) for
progress against `pr1.txt`.
