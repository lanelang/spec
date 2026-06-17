# Lane Specification

This directory contains the formal Lane language specification.

- `language-spec.typ`: Typst source for the specification.
- `language-spec.pdf`: rendered specification.

Executable conformance fixtures live in
[`lanelang/lane/examples`](https://github.com/lanelang/lane/tree/main/examples).

Build the rendered specification from the repository root:

```sh
typst compile --root . language-spec.typ language-spec.pdf
```
