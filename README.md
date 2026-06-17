# Lane Specification

This directory contains the formal Lane language specification.

- `language-spec.typ`: Typst source for the specification.
- `language-spec.pdf`: rendered specification.
- `examples/`: source fixtures used to clarify accepted and rejected Lane programs.

Build the rendered specification from the repository root:

```sh
typst compile --root . language-spec.typ language-spec.pdf
```
