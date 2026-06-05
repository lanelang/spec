# Lane2 Specification

This directory contains the formal Lane2 language specification.

- `language-spec.typ`: Typst source for the specification.
- `language-spec.pdf`: rendered specification.
- `examples/`: source fixtures used to clarify accepted and rejected Lane2 programs.

Build the rendered specification from the repository root:

```sh
typst compile --root . spec/language-spec.typ spec/language-spec.pdf
```
