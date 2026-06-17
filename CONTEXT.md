# Lane Specification

The Lane specification repository owns the normative description of the Lane
source language and Buslane semantic core.

## Language

**Language Specification**:
The Typst document and rendered PDF that define Lane syntax, static semantics,
semantic elaboration, Buslane, and runtime semantics.
_Avoid_: implementation notes, compiler roadmap

**Normative Example**:
A Lane source fixture used to clarify accepted and rejected language behavior.
_Avoid_: compiler unit test, tool smoke test

**Design Record**:
A historical ADR that explains why a language-level rule exists. The final
rule belongs in the language specification.
_Avoid_: implementation task list, stale proposal

## Relationships

- The **Language Specification** is the contract implemented by `lanec`,
  consumed by `stdlib`, and reflected by `lane`, `lane_lsp`, and `lane_vscode`.
- **Normative Examples** describe intended language behavior even when an
  implementation is still catching up.
- Implementation repositories may cite **Design Records**, but should not
  duplicate normative language definitions.
