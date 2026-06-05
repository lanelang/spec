# Lane2 Examples

These files are executable specification fixtures for the first parser, resolver,
type checker, and AST interpreter.

- `valid/*.lane` should parse and type check.
- `invalid/*.lane` should be rejected for the reason stated in the leading
  comment.

The examples assume the v1 prelude described in `../language-spec.typ` is
loaded before user source.
