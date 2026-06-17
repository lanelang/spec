# Lane Examples

These files are executable specification fixtures for the parser, resolver, type
checker, elaborator, Buslane checker, and reference interpreter.

- `valid/*.lane` should parse and type check.
- `invalid/*.lane` should be rejected for the reason stated in the leading
  comment.

The examples follow the language specification rather than the current
implementation. Rejecting a `valid` example or accepting an `invalid` example is
an implementation discrepancy unless the specification changes.

The examples assume the v1 prelude described in `../language-spec.typ` is
loaded before user source.
