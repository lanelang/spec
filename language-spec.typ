#set document(title: "Lane2 Language Specification")
#set page(paper: "a4", margin: 2.4cm)
#set text(size: 10pt)
#set heading(numbering: "1.1")

#let code-box(body) = block(
  width: 100%,
  fill: rgb("#f7f9fb"),
  stroke: 0.5pt + rgb("#d8dee6"),
  radius: 4pt,
  inset: 8pt,
  body,
)

#let math-box(body) = block(
  width: 100%,
  fill: rgb("#fbfaf3"),
  stroke: 0.5pt + rgb("#e2dcc5"),
  radius: 4pt,
  inset: 8pt,
  body,
)

#show raw.where(block: true): it => code-box(it)
#show math.equation.where(block: true): it => math-box(align(center, it))

#let math-list(..items) = stack(
  dir: ttb,
  spacing: 6pt,
  ..items,
)

#align(center)[#text(size: 20pt, weight: "bold")[Lane2 Language Specification]]

#align(center)[
  Version: v1 draft \
  Status: working specification
]

#outline(title: "Contents")

#let rule(premise, conclusion) = align(center)[$ frac(#premise, #conclusion) $]

= Introduction

Lane2 is a strict, pure, expression-oriented functional programming language. Its first implementation target is a parser, a type checker, and an AST interpreter; later implementations may add bytecode compilation, a virtual machine, a linker, and effect handling.

Lane2 is intentionally small. It has no mutable state, assignment, trait system, method dispatch, module system, or implicit typeclass-style instance search in v1. Instead, v1 is centered on nominal data, first-class functions, bidirectional local type inference, exhaustive pattern matching, and explicit operation values opened into lexical scope.

This document specifies Lane2/Core v1: the platform-independent part of Lane2 that should behave the same across the initial AST interpreter and later execution backends.

== Scope

Lane2/Core v1 covers:

- source structure and declarations;
- lexical scope and name resolution;
- nominal struct and enum types;
- function and block expressions;
- local type inference;
- pattern matching;
- `open`, `preopen`, and operation-based operators;
- unsafe builtin expressions.

The following are outside Lane2/Core v1:

- mutation and assignment;
- modules and imports;
- bytecode and virtual machine semantics;
- linker entrypoint selection;
- algebraic effects;
- type aliases;
- traits, typeclasses, and interfaces;
- tuples and collection syntax.

== Compatibility

This specification is a v1 draft. No compatibility is promised between draft revisions. Language rules may be added, removed, or changed while the first implementation is being developed.

Once a v1 implementation is declared stable, this section should be replaced by an explicit compatibility policy.

== Experimental Features

This draft does not distinguish stable and experimental language features. Every rule in this document is provisional until v1 is stabilized.

Future drafts may mark individual features as experimental when their surface syntax or semantics are intentionally unsettled.

== Feedback

Design feedback is tracked in the Lane2 repository. Implementation changes should update this specification, `docs/language-v1.md`, `docs/prelude-v1.md`, `CONTEXT.md`, and ADRs when the change affects user-visible semantics.

== Reference

When referencing this draft, use:

> Lane2 Language Specification : Lane2/Core v1 draft.

= Syntax and Grammar

== Notation

```text
grammar        ::= { production }
production     ::= nonTerminal "::=" grammarExpression
grammarExpression ::=
    grammarSequence { "|" grammarSequence }
grammarSequence ::=
    { grammarItem }
grammarItem ::=
    terminal
  | nonTerminal
  | "[" grammarExpression "]"
  | "{" grammarExpression "}"
  | "(" grammarExpression ")"
  | grammarItem "?"
  | grammarItem "*"
  | grammarItem "+"

terminal       ::= "'" terminalText "'"
nonTerminal    ::= lowerCamelIdentifier

empty sequence denotes epsilon.
"A B" denotes sequencing.
"A | B" denotes choice.
"[ A ]" and "A?" denote optional occurrence.
"{ A }" and "A*" denote zero or more occurrences.
"A+" denotes one or more occurrences.
Parenthesized grammar expressions group without producing syntax.
```

== Lexical Grammar

```text
lexicalInput ::=
    (trivia | token)* eof

trivia ::=
    whitespace
  | lineTerminator
  | comment

token ::=
    keyword
  | reservedWord
  | identifier
  | intLiteral
  | stringLiteral
  | boolLiteral
  | operatorToken
  | punctuationToken

keyword ::=
    "struct"
  | "enum"
  | "fn"
  | "let"
  | "open"
  | "if"
  | "else"
  | "match"
  | "builtin"

reservedWord ::=
    "effect"
  | "handler"
  | "module"
  | "import"
  | "pub"
  | "type"
  | "trait"
  | "interface"
  | "mut"
  | "return"

identifier ::=
    xidStart identifierContinue*
  | "_" identifierContinue+

identifierContinue ::=
    "_"
  | xidContinue
  | decimalDigit

boolLiteral ::=
    "true"
  | "false"

intLiteral ::=
    decimalDigit+

stringLiteral ::=
    "\"" stringElement* "\""

stringElement ::=
    asciiStringCharacter
  | stringEscape

asciiStringCharacter ::=
    asciiCodePointExceptControlBackslashQuote

stringEscape ::=
    "\\" "\\"
  | "\\" "\""
  | "\\" "n"
  | "\\" "r"
  | "\\" "t"
  | "\\" "x" asciiHexByte

asciiHexByte ::=
    asciiHexLowByte
  | asciiHexHighByte

asciiHexLowByte ::=
    ("0" | "1" | "2" | "3" | "4" | "5" | "6") asciiHexDigit

asciiHexHighByte ::=
    "7" ("0" | "1" | "2" | "3" | "4" | "5" | "6" | "7")

operatorToken ::=
    "+"
  | "-"
  | "*"
  | "/"
  | "%"
  | "=="
  | "!="
  | "<"
  | "<="
  | ">"
  | ">="
  | "&&"
  | "||"
  | "!"
  | "|>"

punctuationToken ::=
    "("
  | ")"
  | "{"
  | "}"
  | "["
  | "]"
  | ","
  | "."
  | ":"
  | "::"
  | "->"
  | "=>"
  | "="
  | "_"

whitespace ::=
    U+0009
  | U+000B
  | U+000C
  | U+0020

lineTerminator ::=
    U+000A
  | U+000D
  | U+000D U+000A

decimalDigit ::=
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"

asciiHexDigit ::=
    decimalDigit
  | "a" | "b" | "c" | "d" | "e" | "f"
  | "A" | "B" | "C" | "D" | "E" | "F"

xidStart ::=
    any Unicode code point with the XID_Start property

xidContinue ::=
    any Unicode code point with the XID_Continue property
```

Lexical analysis uses maximal munch. If more than one token class matches the same maximal source span, keyword, reservedWord, and boolLiteral take priority over identifier.

== Syntax Grammar

```text
sourceFile ::=
    topLevelDeclaration* eof

topLevelDeclaration ::=
    structDeclaration
  | enumDeclaration
  | functionDeclaration
  | topLevelLetDeclaration
  | anonymousTopLevelLetDeclaration
  | openDeclaration

structDeclaration ::=
    "struct" typeName typeParameters? "{" structMember* "}"

structMember ::=
    fieldDeclaration
  | fieldForwardingDeclaration

fieldDeclaration ::=
    fieldName space ":" space type

fieldForwardingDeclaration ::=
    "open" valueName

enumDeclaration ::=
    "enum" typeName typeParameters? "{" enumVariant* "}"

enumVariant ::=
    variantName enumPayload?

enumPayload ::=
    "(" commaSeparatedTypes? ")"

functionDeclaration ::=
    "fn" typeParameters? functionName "(" commaSeparatedParameters? ")" "->" type block

parameter ::=
    valueName space ":" space type

topLevelLetDeclaration ::=
    "let" valueName space ":" space type "=" expression

anonymousTopLevelLetDeclaration ::=
    "let" space ":" space type "=" expression

localLetDeclaration ::=
    "let" valueName typeAnnotation? "=" expression

typeAnnotation ::=
    space ":" space type

openDeclaration ::=
    "open" valueName

type ::=
    typeConstructor typeArguments?
  | functionType

typeConstructor ::=
    typeName

typeArguments ::=
    "[" commaSeparatedTypes "]"

typeParameters ::=
    "[" commaSeparatedTypeParameters "]"

functionType ::=
    typeParameters? "(" commaSeparatedTypes? ")" "->" type

expression ::=
    ifExpression
  | matchExpression
  | functionLiteral
  | block
  | pipelineExpression

pipelineExpression ::=
    binaryExpression { "|>" pipelineRhs }

pipelineRhs ::=
    callExpression
  | functionLiteral

binaryExpression ::=
    unaryExpression { binaryOperator unaryExpression }

unaryExpression ::=
    unaryOperator unaryExpression
  | callExpression

callExpression ::=
    fieldExpression { callSuffix }

callSuffix ::=
    "(" commaSeparatedExpressions? ")"

fieldExpression ::=
    primaryExpression { "." fieldName }

primaryExpression ::=
    literal
  | valueName
  | qualifiedVariantExpression
  | structLiteral
  | builtinExpression
  | "(" expression ")"
  | "(" ")"

literal ::=
    intLiteral
  | stringLiteral
  | boolLiteral

qualifiedVariantExpression ::=
    typeName typeArguments? "::" variantName variantArguments?

variantArguments ::=
    "(" commaSeparatedExpressions? ")"

structLiteral ::=
    typeName typeArguments? "::" "{" commaSeparatedStructLiteralFields "}"

structLiteralField ::=
    fieldName
  | fieldName ":" expression

builtinExpression ::=
    "builtin" "(" stringLiteral ")"

functionLiteral ::=
    "fn" typeParameters? "(" commaSeparatedFunctionLiteralParameters? ")" functionReturnAnnotation? block

functionLiteralParameter ::=
    valueName
  | valueName space ":" space type

functionReturnAnnotation ::=
    "->" type

block ::=
    "{" localItem* expression "}"

localItem ::=
    localLetDeclaration
  | functionDeclaration
  | openDeclaration

ifExpression ::=
    "if" expression block "else" block

matchExpression ::=
    "match" expression "{" matchArm* "}"

matchArm ::=
    pattern "=>" expression

pattern ::=
    "_"
  | valueName
  | literal
  | qualifiedVariantPattern
  | structPattern

qualifiedVariantPattern ::=
    typeName "::" variantName patternArguments?

patternArguments ::=
    "(" commaSeparatedPatterns? ")"

structPattern ::=
    typeName "::" "{" commaSeparatedStructPatternFields "}"

structPatternField ::=
    fieldName
  | fieldName ":" pattern

binaryOperator ::=
    "+" | "-" | "*" | "/" | "%"
  | "==" | "!=" | "<" | "<=" | ">" | ">="
  | "&&" | "||"

unaryOperator ::=
    "-" | "!"

commaSeparatedTypes ::=
    type ("," type)* ","?

commaSeparatedTypeParameters ::=
    typeParameter ("," typeParameter)* ","?

commaSeparatedParameters ::=
    parameter ("," parameter)* ","?

commaSeparatedExpressions ::=
    expression ("," expression)* ","?

commaSeparatedFunctionLiteralParameters ::=
    functionLiteralParameter ("," functionLiteralParameter)* ","?

commaSeparatedStructLiteralFields ::=
    structLiteralField ("," structLiteralField)* ","?

commaSeparatedPatterns ::=
    pattern ("," pattern)* ","?

commaSeparatedStructPatternFields ::=
    structPatternField ("," structPatternField)* ","?

typeName ::=
    identifier

functionName ::=
    identifier

valueName ::=
    identifier

fieldName ::=
    identifier

variantName ::=
    identifier

typeParameter ::=
    identifier

space ::=
    whitespace+
```

The precedence and associativity of `binaryOperator`, `unaryOperator`, calls, field access, and pipeline expressions are defined in "Operators".

== Comments

```text
comment ::=
    lineComment
  | blockComment

lineComment ::=
    "/" "/" lineCommentCharacter* lineTerminator?

lineCommentCharacter ::=
    any Unicode code point except U+000A or U+000D

blockComment ::=
    "/" "*" blockCommentCharacter* "*" "/"

blockCommentCharacter ::=
    any Unicode code point sequence that does not start "*/"
```

Comments are trivia. Comments do not appear in the syntactic grammar.

= Type System

== Notations

#figure(caption: [Type system notations])[
  #table(
    columns: (auto, 1fr),
    [Notation], [Meaning],
    [$T, U, R, F, P, Q$], [types],
    [$A$], [type variable],
    [$C$], [type constructor],
    [$S$], [struct type constructor],
    [$E$], [enum type constructor],
    [$e, c, f, b$], [expressions],
    [$a$], [match arm],
    [$x$], [value binder],
    [$i, j, k, n, m, q$], [indices and natural numbers],
    [$l$], [struct field name],
    [$v$], [enum variant name],
    [$#sym.Delta$], [type-constructor context],
    [$#sym.Theta$], [type-variable context],
    [$#sym.Gamma$], [value typing context],
    [$D$], [custom type definition],
    [$#sym.Delta (C) = D$], [visible custom type definition],
    [$op("struct")(A_1, ..., A_n; l_1 : F_1, ..., l_m : F_m)$], [struct definition],
    [$op("enum")(A_1, ..., A_n; v_j(P_(j,1), ..., P_(j,m_j)))$], [enum definition],
    [$op("params")(D) = (A_1, ..., A_n)$], [custom type parameters],
    [$#sym.sigma$], [type substitution environment],
    [$#sym.sigma = [T_1 #sym.slash A_1, ..., T_n #sym.slash A_n]$], [substitution environment binding],
    [$U[T_1 #sym.slash A_1, ..., T_n #sym.slash A_n]$], [direct type substitution],
    [$U #sym.sigma$], [type substitution by environment],
    [$#sym.Delta; #sym.Theta #sym.tack.r T " type"$], [well-formed type],
    [$C[T_1, ..., T_n]$], [nominal type application],
    [$#sym.forall A_1, ..., A_n "." T$], [universal type],
    [$T #sym.eq.triple U$], [type equality],
    [$#sym.Gamma #sym.tack.r e : T$], [expression typing],
    [$op("fields")(S[T_1, ..., T_n]) = (l_1 : Q_1, ..., l_m : Q_m)$], [instantiated struct fields],
    [$op("payloads")(E[T_1, ..., T_n], v) = (Q_1, ..., Q_m)$], [instantiated variant payloads],
    [$op("binders")(#sym.Gamma; x_1 : Q_1, ..., x_m : Q_m) = #sym.Gamma'$], [extended pattern-binder context],
    [$op("arm-type")(E[T_1, ..., T_n], R)$], [typed enum match arm],
    [$frac(P, Q)$], [rule with premise $P$ and conclusion $Q$],
    [$op("name")$], [abstract syntax constructor],
  )
]

== Primitive Types

Lane2/Core v1 has four primitive types: `Unit`, `Bool`, `Int`, and `String`.

*Primitive formation.* Each primitive type is well-formed in every type environment.

#math-list(
  $ #sym.Delta; #sym.Theta #sym.tack.r "Unit" " type" $,
  $ #sym.Delta; #sym.Theta #sym.tack.r "Bool" " type" $,
  $ #sym.Delta; #sym.Theta #sym.tack.r "Int" " type" $,
  $ #sym.Delta; #sym.Theta #sym.tack.r "String" " type" $,
)

*Unit introduction.* The expression `()` introduces a `Unit` value.

```lane2
() // unit literal
```

$ #sym.Gamma #sym.tack.r () : "Unit" $

*Unit elimination.* Lane2/Core v1 has no dedicated elimination form for `Unit`.

*Bool introduction.* Boolean literals introduce `Bool` values.

```lane2
true  // boolean literal
false // boolean literal
```

#math-list(
  $ #sym.Gamma #sym.tack.r "true" : "Bool" $,
  $ #sym.Gamma #sym.tack.r "false" : "Bool" $,
)

*Bool elimination.* `if` eliminates a `Bool` value.

```lane2
if c {
  e1
} else {
  e2
} // c : Bool, e1 : T, e2 : T
```

#rule[
  $ #sym.Gamma #sym.tack.r c : "Bool" quad #sym.Gamma #sym.tack.r e_1 : T quad #sym.Gamma #sym.tack.r e_2 : T $
][
  $ #sym.Gamma #sym.tack.r op("if")(c, e_1, e_2) : T $
]

*Int introduction.* Integer literals introduce `Int` values.

```lane2
n // integer literal
```

$ #sym.Gamma #sym.tack.r n : "Int" $

*Int elimination.* Lane2/Core v1 has no built-in syntactic eliminator for `Int`. Integer operations are typed through required intrinsics and prelude operation values.

*String introduction.* ASCII string literals introduce `String` values.

```lane2
"..." // ASCII string literal
```

$ #sym.Gamma #sym.tack.r s : "String" $

*String elimination.* Lane2/Core v1 has no built-in syntactic eliminator for `String`. String equality is typed through the prelude.

*Primitive type equality.* Primitive types are equal only to themselves.

#math-list(
  $ "Unit" #sym.eq.triple "Unit" $,
  $ "Bool" #sym.eq.triple "Bool" $,
  $ "Int" #sym.eq.triple "Int" $,
  $ "String" #sym.eq.triple "String" $,
)

== Function Types

*Function formation.*

```lane2
fn f(x1 : T1, ..., xn : Tn) -> R { e } // function definition
let f : (T1, ..., Tn) -> R = fn(x1, ..., xn) { e } // function literal binding
```

#rule[
  $ #sym.Delta; #sym.Theta #sym.tack.r T_1 " type" quad ... quad #sym.Delta; #sym.Theta #sym.tack.r T_n " type" quad #sym.Delta; #sym.Theta #sym.tack.r R " type" $
][
  $ #sym.Delta; #sym.Theta #sym.tack.r (T_1, ..., T_n) -> R " type" $
]

*Function introduction.*

```lane2
fn(x1 : T1, ..., xn : Tn) -> R { e } // function literal
fn f(x1 : T1, ..., xn : Tn) -> R { e } // function definition
```

#rule[
  $ #sym.Gamma, x_1 : T_1, ..., x_n : T_n #sym.tack.r e : R $
][
  $ #sym.Gamma #sym.tack.r op("fn")((x_1 : T_1), ..., (x_n : T_n), R, e) : (T_1, ..., T_n) -> R $
]

*Function elimination.*

```lane2
f(a1, ..., an) // function call
```

#rule[
  $ #sym.Gamma #sym.tack.r f : (T_1, ..., T_n) -> R quad #sym.Gamma #sym.tack.r a_1 : T_1 quad ... quad #sym.Gamma #sym.tack.r a_n : T_n $
][
  $ #sym.Gamma #sym.tack.r f(a_1, ..., a_n) : R $
]

*Function type equality.*

#rule[
  $ T_1 #sym.eq.triple U_1 quad ... quad T_n #sym.eq.triple U_n quad R #sym.eq.triple S $
][
  $ (T_1, ..., T_n) -> R #sym.eq.triple (U_1, ..., U_n) -> S $
]

Function types are uncurried. `(T1, T2) -> R` is not the same type object as `(T1) -> (T2) -> R`.

== Generic Function Types

*Generic function formation.*

```lane2
[A1, ..., An](T1, ..., Tm) -> R // generic function type
```

#rule[
  $ #sym.Delta; #sym.Theta, A_1, ..., A_n #sym.tack.r (T_1, ..., T_m) -> R " type" $
][
  $ #sym.Delta; #sym.Theta #sym.tack.r #sym.forall A_1, ..., A_n "." (T_1, ..., T_m) -> R " type" $
]

*Generic function introduction.*

```lane2
fn[A1, ..., An](x1 : T1, ..., xm : Tm) -> R { e } // generic function literal
fn[A1, ..., An] f(x1 : T1, ..., xm : Tm) -> R { e } // generic function definition
```

A generic function literal or named generic function introduces a generic function value.

*Generic function elimination.*

Generic function calls instantiate type parameters at the use site when the use site is unambiguous.

```lane2
f(a1, ..., am) // generic function call with inferred type arguments
```

*Generic function type equality.*

#rule[
  $ (T_1, ..., T_m) -> R #sym.eq.triple (U_1, ..., U_m) -> S $
][
  $ #sym.forall A_1, ..., A_n "." (T_1, ..., T_m) -> R #sym.eq.triple #sym.forall A_1, ..., A_n "." (U_1, ..., U_m) -> S $
]

Generic function type equality compares the number of type parameters and the function types under corresponding bound type parameters.

== Nominal Custom Types

Struct and enum declarations introduce nominal custom type definitions in #sym.Delta.

```lane2
struct S[A1, ..., An] {
  l1 : F1
  ...
  lm : Fm
} // struct definition
```

```lane2
enum E[A1, ..., An] {
  v1(P11, ..., P1m1)
  ...
  vj(Pj1, ..., Pjmj)
} // enum definition
```

The type-constructor context stores the full declaration shape, not only arity.

#math-list(
  $ #sym.Delta (S) = op("struct")(A_1, ..., A_n; l_1 : F_1, ..., l_m : F_m) $,
  $ #sym.Delta (E) = op("enum")(A_1, ..., A_n; v_j(P_(j,1), ..., P_(j,m_j))) $,
)

Top-level custom type declarations are checked in two phases. First, all top-level struct and enum constructors are collected into #sym.Delta with their type parameters, field names, variant names, and declared member type expressions. Second, every field type and variant payload type is checked under the collected #sym.Delta and the declaration's type parameters. This permits mutually recursive custom types.

#rule[
  $ #sym.Delta (S) = op("struct")(A_1, ..., A_n; l_1 : F_1, ..., l_m : F_m) quad #sym.forall i "." #sym.Delta; A_1, ..., A_n #sym.tack.r F_i " type" $
][
  $ #sym.Delta #sym.tack.r S " declaration" $
]

#rule[
  $ #sym.Delta (E) = op("enum")(A_1, ..., A_n; v_j(P_(j,1), ..., P_(j,m_j))) quad #sym.forall j,k "." #sym.Delta; A_1, ..., A_n #sym.tack.r P_(j,k) " type" $
][
  $ #sym.Delta #sym.tack.r E " declaration" $
]

*Nominal formation.* A nominal type application is well-formed when its custom type constructor is visible, the number of type arguments matches the declaration's type parameters, and every type argument is well-formed.

#rule[
  $ #sym.Delta (C) = D quad op("params")(D) = (A_1, ..., A_n) quad #sym.Delta; #sym.Theta #sym.tack.r T_1 " type" quad ... quad #sym.Delta; #sym.Theta #sym.tack.r T_n " type" $
][
  $ #sym.Delta; #sym.Theta #sym.tack.r C[T_1, ..., T_n] " type" $
]

*Nominal type equality.* Nominal type equality compares constructor identity and then compares type arguments pairwise. There is no equality rule whose conclusion relates different nominal constructors.

#rule[
  $ T_1 #sym.eq.triple U_1 quad ... quad T_n #sym.eq.triple U_n $
][
  $ C[T_1, ..., T_n] #sym.eq.triple C[U_1, ..., U_n] $
]

== Struct Types

*Struct introduction.* A qualified struct literal introduces a struct value. It must provide every declared field exactly once. Source field order is not significant; the rule below uses declaration order.

```lane2
S[T1, ..., Tn]::{ l1: e1, ..., lm: em } // qualified struct literal
```

#rule[
  $ #sym.Delta (S) = op("struct")(A_1, ..., A_n; l_1 : F_1, ..., l_m : F_m) quad #sym.sigma = [T_1 #sym.slash A_1, ..., T_n #sym.slash A_n] $
][
  $ op("fields")(S[T_1, ..., T_n]) = (l_1 : F_1 #sym.sigma, ..., l_m : F_m #sym.sigma) $
]

#rule[
  $ op("fields")(S[T_1, ..., T_n]) = (l_1 : Q_1, ..., l_m : Q_m) quad #sym.Gamma #sym.tack.r e_1 : Q_1 quad ... quad #sym.Gamma #sym.tack.r e_m : Q_m $
][
  $ #sym.Gamma #sym.tack.r op("struct-lit")(S[T_1, ..., T_n], l_1 = e_1, ..., l_m = e_m) : S[T_1, ..., T_n] $
]

*Struct field elimination.* Field access eliminates a struct value by selecting a declared field type after substituting the struct type arguments.

```lane2
e.l // field access
```

#rule[
  $ #sym.Gamma #sym.tack.r e : S[T_1, ..., T_n] quad op("fields")(S[T_1, ..., T_n]) = (..., l : Q, ...) $
][
  $ #sym.Gamma #sym.tack.r e.l : Q $
]

Struct values are also eliminated by struct patterns and exposed by `open`; their detailed static rules are specified in "Pattern Matching" and "Structs, Enums, and Open".

== Enum Types

*Enum variant introduction.* A qualified enum variant expression introduces an enum value. The payload expressions must match the declared variant payload types after substituting the enum type arguments.

```lane2
E[T1, ..., Tn]::v(e1, ..., em) // qualified variant expression
v(e1, ..., em) // unqualified variant expression after unambiguous resolution
```

#rule[
  $ #sym.Delta (E) = op("enum")(A_1, ..., A_n; ..., v(P_1, ..., P_m), ...) $
][
  $ op("payloads")(E[T_1, ..., T_n], v) = (P_1[T_1 #sym.slash A_1, ..., T_n #sym.slash A_n], ..., P_m[T_1 #sym.slash A_1, ..., T_n #sym.slash A_n]) $
]

#rule[
  $ op("payloads")(E[T_1, ..., T_n], v) = (Q_1, ..., Q_m) quad #sym.Gamma #sym.tack.r e_1 : Q_1 quad ... quad #sym.Gamma #sym.tack.r e_m : Q_m $
][
  $ #sym.Gamma #sym.tack.r op("variant")(E[T_1, ..., T_n], v, e_1, ..., e_m) : E[T_1, ..., T_n] $
]

An unqualified enum variant expression is typed by the same rule after name resolution has selected exactly one visible enum variant.

*Enum match elimination.* A match expression eliminates an enum value. For an enum scrutinee type, every declared variant must be covered.

```lane2
match e {
  E::v1(x11, ..., x1m1) => b1
  ...
  E::vq(xq1, ..., xqmq) => bq
}
```

#rule[
  $ op("payloads")(E[T_1, ..., T_n], v) = (Q_1, ..., Q_m) $
][
  $ op("binders")(#sym.Gamma; x_1 : Q_1, ..., x_m : Q_m) = #sym.Gamma' $
]

#rule[
  $ op("payloads")(E[T_1, ..., T_n], v) = (Q_1, ..., Q_m) quad op("binders")(#sym.Gamma; x_1 : Q_1, ..., x_m : Q_m) = #sym.Gamma' quad #sym.Gamma' #sym.tack.r b : R $
][
  $ #sym.Gamma #sym.tack.r op("arm")(v(x_1, ..., x_m) => b) : op("arm-type")(E[T_1, ..., T_n], R) $
]

#rule[
  $ #sym.Gamma #sym.tack.r e : E[T_1, ..., T_n] quad #sym.Delta (E) = op("enum")(A_1, ..., A_n; v_1, ..., v_q) quad #sym.Gamma #sym.tack.r a_j : op("arm-type")(E[T_1, ..., T_n], R) $
][
  $ #sym.Gamma #sym.tack.r op("match")(e; a_1, ..., a_q) : R $
]

Pattern syntax and exhaustiveness diagnostics are specified in "Pattern Matching".

= Type Inference

Lane2 permits local type inference only at syntactic positions where the omitted type is determined locally.

A binding's type is not determined from later uses of the bound name.

Local `let` bindings may omit type annotations only when the initializer has a type without using later references to the bound name.

Function literals may omit parameter types only when the immediately surrounding context provides a function type. Otherwise, every value parameter of a function literal must have an explicit type annotation.

Generic function literals without an immediately surrounding generic function type must explicitly declare type parameters and explicitly annotate value parameters.

Generic function calls and generic data constructors may instantiate type parameters at the use site when the use site is unambiguous.

= Builtins

`builtin("...")` is an unsafe expression.

The checker does not interpret intrinsic strings. Instead, `builtin` receives its type from direct expected context:

```lane2
fn int_add(a : Int, b : Int) -> Int {
  builtin("%i64_add")
}
```

This is valid because the function return type provides the expected type `Int` for the body expression.

This is invalid:

```lane2
let x = builtin("%anything")
```

There is no direct expected type.

Incorrect builtin use can produce undefined behavior. Lane2's type safety guarantee applies only to programs that do not misuse `builtin`.

== Required Intrinsics

A conforming Lane2/Core v1 implementation provides these portable intrinsic names:

#figure(caption: [Required intrinsic names and expected types])[
  #table(
    columns: (auto, 1fr),
    [Intrinsic], [Expected type],
    [`%i64_add`], [`(Int, Int) -> Int`],
    [`%i64_sub`], [`(Int, Int) -> Int`],
    [`%i64_mul`], [`(Int, Int) -> Int`],
    [`%i64_div`], [`(Int, Int) -> Int`],
    [`%i64_rem`], [`(Int, Int) -> Int`],
    [`%i64_neg`], [`(Int) -> Int`],
    [`%i64_equal`], [`(Int, Int) -> Bool`],
    [`%i64_less`], [`(Int, Int) -> Bool`],
    [`%string_equal`], [`(String, String) -> Bool`],
  )
]

Other intrinsic names are implementation-defined unsafe builtins.

`%bool_and`, `%bool_or`, `%bool_not`, and `%bool_equal` are not required intrinsics. The standard prelude defines boolean operations as ordinary Lane2 functions and anonymous operation values using `if`; `&&` and `||` supply their right operands as thunks.

= Prelude

The standard prelude is implementation-supplied Lane2 source checked before user code. It is not a module system.

Prelude declarations provide standard operation structs, primitive wrappers around required intrinsics, derived primitive operations written in Lane2, and anonymous top-level values that populate the initial preopen namespace.

Prelude entries are ordinary Lane2 values and types except where the compiler recognizes operation field pairs for operator aliases.

== Standard Operation Structs

Arithmetic operations:

```lane2
struct Add[T] {
  add : (T, T) -> T
}

struct Sub[T] {
  sub : (T, T) -> T
}

struct Mul[T] {
  mul : (T, T) -> T
}

struct Div[T] {
  div : (T, T) -> T
}

struct Rem[T] {
  rem : (T, T) -> T
}

struct Neg[T] {
  neg : (T) -> T
}
```

Boolean operations:

```lane2
struct And {
  and : (Bool, () -> Bool) -> Bool
}

struct Or {
  or : (Bool, () -> Bool) -> Bool
}

struct Not {
  not : (Bool) -> Bool
}
```

Equality and ordering operations:

```lane2
struct Equal[T] {
  equal : (T, T) -> Bool
  not_equal : (T, T) -> Bool
}

struct Compare[T] {
  equal_impl : Equal[T]
  open equal_impl
  less : (T, T) -> Bool
  less_eq : (T, T) -> Bool
  greater : (T, T) -> Bool
  greater_eq : (T, T) -> Bool
}
```

Operation laws are API conventions, not compiler-checked rules.

== Standard Preopen Values

The prelude may populate the initial preopen namespace with anonymous top-level values. For example, primitive arithmetic and boolean operations can be exposed as follows:

```lane2
let : Add[Int] = Add::{ add: int_add }
let : Sub[Int] = Sub::{ sub: int_sub }
let : Mul[Int] = Mul::{ mul: int_mul }
let : Div[Int] = Div::{ div: int_div }
let : Rem[Int] = Rem::{ rem: int_rem }
let : Neg[Int] = Neg::{ neg: int_neg }

let int_equal_ops : Equal[Int] = make_equal(int_equal)
let : Compare[Int] = make_compare(int_equal_ops, int_less)

let : And = And::{ and: bool_and }
let : Or = Or::{ or: bool_or }
let : Not = Not::{ not: bool_not }
let : Equal[Bool] = Equal::{
  equal: fn(a : Bool, b : Bool) {
    if a {
      b
    } else {
      bool_not(b)
    }
  },
  not_equal: fn(a : Bool, b : Bool) {
    if a {
      bool_not(b)
    } else {
      b
    }
  },
}

let : Equal[String] = make_equal(string_equal)
```

Boolean conjunction, disjunction, negation, and equality do not require boolean intrinsics; they can be defined with ordinary `if` expressions in the prelude.

= Declarations

Declarations introduce types, functions, values, and open scope extensions.

== Top-Level Declarations

Top-level declarations are described by the `topLevelDefinition` grammar in "Syntax and Grammar".

Top-level forms include struct declarations, enum declarations, named function declarations, typed value declarations, anonymous typed value declarations, and open declarations.

== Struct Declarations

Struct declarations use the grammar in "Structs, Enums, and Open".

== Enum Declarations

Enum declarations use the grammar in "Structs, Enums, and Open".

== Function Declarations

Functions are uncurried. There is no automatic currying or partial application.

Function definitions use block bodies:

```text
functionDeclaration:
    'fn' [ typeParameters ] functionName '(' [ parameter { ',' parameter } [ ',' ] ] ')' '->' type block

parameter:
    valueName ':' type

functionLiteral:
    'fn' [ typeParameters ] '(' [ functionLiteralParameter { ',' functionLiteralParameter } [ ',' ] ] ')' [ '->' type ] block

functionLiteralParameter:
    valueName
  | valueName ':' type
```

```lane2
fn add(a : Int, b : Int) -> Int {
  a + b
}
```

There is no `= expr` function body form.

Function result types use `->`, not `:`.

All named functions must state every parameter type and the result type.

Generic named functions place type parameters after `fn` and before the name:

```lane2
fn[A] id(value : A) -> A {
  value
}
```

Function parameters are positional in v1. Labeled function parameters are not supported.

Function literals produce function values:

```lane2
let f : (Int, Int) -> Int = fn(a, b) {
  a + b
}
```

Generic function literals place type parameters after `fn`:

```lane2
let id = fn[A](value : A) {
  value
}
```

== Let Declarations

Named top-level `let` declarations must include type annotations. Anonymous top-level `let` declarations must include type annotations and must have a struct type.

Local `let` declarations may omit type annotations when their initializer can synthesize a type by local type inference.

= Scopes and Bindings

Top-level type and function definitions form recursive definition groups.

Top-level `struct`, `enum`, and `fn` definitions may refer to each other regardless of textual order.

Top-level value definitions and top-level `open` declarations follow ordered value scope:

- a top-level `let` initializer may refer only to values already available at that declaration point;
- a top-level `open` may open only a value already available at that declaration point;
- a top-level function body may refer to any top-level value or function, even one declared later.

Example:

```lane2
fn read_x() -> Int {
  x
}

let x : Int = 1
```

This is valid because the function body sees the complete top-level environment.

```lane2
let y : Int = x
let x : Int = 1
```

This is invalid because top-level value initializers follow ordered value scope.

== Namespaces

Lane2 has separate type and value namespaces.

Type and value names may use the same spelling:

```lane2
enum Option[A] {
  none
  some(A)
}

let Option : Int = 42
```

Syntax of the form `Type::member` resolves `Type` in the type namespace.

```lane2
let x : Option[Int] = Option::some(1)
```

The `Option` on the left of `::` denotes the enum type, not the value named `Option`.

== Local Bindings

Local `let` bindings are sequential. A local binding is visible only to later items and the final expression in the same block.

Local `let` bindings may omit type annotations when their initializer can synthesize a type by local type inference:

```lane2
let x = 1
```

Local named functions are also sequential. They may call themselves, but local mutually recursive groups and forward references are not supported:

```lane2
fn f(n : Int) -> Int {
  fn loop(x : Int) -> Int {
    if x == 0 {
      0
    } else {
      loop(x - 1)
    }
  }
  loop(n)
}
```

Local value names may shadow earlier local value names.

== Open Scope Extensions

`open value` opens a struct value.

The operand of `open` must be a visible value name with a struct type. It cannot be an arbitrary expression:

```lane2
open ops
```

This is invalid:

```lane2
open make_ops(10)
```

An open scope extension exposes the struct field values as unqualified names from the declaration point to the end of the current lexical scope.

At top level, `open` extends to the end of the file:

```lane2
open int_add_ops

fn add_one(x : Int) -> Int {
  x + 1
}
```

Inside blocks, `open` is a local item and must appear before the final expression:

```lane2
{
  open int_add_ops
  x + y
}
```

Local resolution uses the nearest preceding local binding or open scope extension, then falls back to preopen.

== Preopen

The preopen namespace is a default-open namespace populated by anonymous top-level values.

```lane2
let : Add[Int] = Add::{ add: int_add }
```

An anonymous top-level value must have a struct type. It exposes field values, not generated accessors.

Prelude-provided anonymous values are checked before user code, so their preopen entries are visible throughout user code.

User-defined anonymous top-level values extend preopen from their declaration point to the end of the top-level scope.

Preopen conflicts are errors.

Top-level `open` belongs to the global layer and conflicts with ordinary top-level names or preopened names. Local `open` may shadow preopen inside its lexical scope.

= Expressions

Expressions compute values. Lane2 v1 is expression-oriented and has no expression statements.

== Blocks

A block expression contains local items followed by one final expression.

```text
block:
    '{' { localItem } expression '}'

localItem:
    localLet
  | localFunctionDeclaration
  | openDeclaration

localLet:
    'let' valueName [ ':' type ] '=' expression

topLevelLet:
    'let' valueName ':' type '=' expression

anonymousTopLevelLet:
    'let' ':' type '=' expression

openDeclaration:
    'open' valueName
```

```lane2
{
  let x = 1
  fn double(n : Int) -> Int {
    n + n
  }
  double(x)
}
```

Allowed local items:

- `let`,
- named `fn`,
- `open`.

Local type definitions are not supported in v1.

A block does not contain expression statements. This is invalid:

```lane2
{
  f(x)
  g(y)
}
```

An empty block is invalid. Write `()` explicitly when a `Unit` value is required.

== Conditional Expressions

`if` is an expression:

```lane2
if condition {
  then_value
} else {
  else_value
}
```

The `else` branch is mandatory.

Both branches must have the same type.

== Calls, Field Access, and Pipeline

Function call:

```lane2
f(x, y)
```

Field access:

```lane2
ops.add
```

Field access followed by call:

```lane2
ops.add(x, y)
```

This is not method call syntax. Lane2 v1 has no method receiver lookup.

Pipeline syntax is supported:

```lane2
value |> f(a, b)
```

It rewrites to:

```lane2
f(value, a, b)
```

The right-hand side of `|>` must be a call or function literal.

The following are invalid:

```lane2
value |> f
value |> f(_, y)
```

Placeholders are not supported.

= Structs, Enums, and Open

```text
structDeclaration:
    'struct' typeName [ typeParameters ] '{' { structMember } '}'

structMember:
    fieldDeclaration
  | fieldForwarding

fieldDeclaration:
    fieldName ':' type

fieldForwarding:
    'open' fieldName

structLiteral:
    typeName [ typeArguments ] '::' '{' structLiteralField { ',' structLiteralField } [ ',' ] '}'

structLiteralField:
    fieldName
  | fieldName ':' expression
```

Struct literals are qualified:

```lane2
let p : Point = Point::{ x: 1, y: 2 }
```

Struct field punning is allowed:

```lane2
let p : Point = Point::{ x, y }
```

This is equivalent to:

```lane2
let p : Point = Point::{ x: x, y: y }
```

Struct literals must provide every field exactly once.

The following are not supported:

- anonymous record literals,
- default fields,
- spread,
- copy update,
- field update.

Fields are accessed with dot syntax:

```lane2
p.x
```

V1 has no field visibility modifiers. Every struct field is accessible wherever the struct value is accessible.

== Enums

```text
enumDeclaration:
    'enum' typeName [ typeParameters ] '{' { enumVariant } '}'

enumVariant:
    variantName [ '(' [ type { ',' type } [ ',' ] ] ')' ]

qualifiedVariantExpression:
    typeName [ typeArguments ] '::' variantName [ '(' [ expression { ',' expression } [ ',' ] ] ')' ]

unqualifiedVariantExpression:
    variantName [ '(' [ expression { ',' expression } [ ',' ] ] ')' ]
```

Enum variants are scoped to their enum.

Variant names may be lowercase or uppercase. Capitalization has no semantic role.

Payloadless variants are values and are written without call parentheses:

```lane2
let x : Option[Int] = Option::none
```

This is invalid:

```lane2
Option::none()
```

Variant payloads are positional:

```lane2
enum Expr {
  int(Int)
  add(Expr, Expr)
}
```

Labeled variant payloads are not part of v1. Named product data must be represented with a struct:

```lane2
struct Node[A] {
  left : Tree[A]
  value : A
  right : Tree[A]
}

enum Tree[A] {
  leaf(A)
  node(Node[A])
}
```

In expressions, unqualified variants are allowed when unambiguous:

```lane2
let x : Option[Int] = some(1)
```

If more than one visible enum has a variant named `some`, the unqualified expression is invalid unless another directly local rule disambiguates it. A qualified variant is always allowed:

```lane2
let x : Option[Int] = Option::some(1)
```

In patterns, variants must always be qualified.

== Openable Struct Values

Only struct values can be opened.

Opening a struct value exposes its field values as unqualified bindings according to the scope rules in "Scopes and Bindings".

Enum values, function values, primitive values, and arbitrary expressions are not openable.

== Struct Field Forwarding

A struct declaration may contain `open field` entries:

```lane2
struct Compare[T] {
  equal_impl : Equal[T]
  open equal_impl
  less : (T, T) -> Bool
  less_eq : (T, T) -> Bool
  greater : (T, T) -> Bool
  greater_eq : (T, T) -> Bool
}
```

When a value of this struct type is opened, forwarded fields are exposed too.

Struct field forwarding affects only what is exposed by opening the containing struct value. It does not open the field inside ordinary function bodies.

= Pattern Matching

`match` is an expression:

```text
matchExpression:
    'match' expression '{' { matchArm } '}'

matchArm:
    pattern '=>' expression

pattern:
    '_'
  | valueName
  | literal
  | qualifiedVariantPattern
  | structPattern

qualifiedVariantPattern:
    typeName '::' variantName [ '(' [ pattern { ',' pattern } [ ',' ] ] ')' ]

structPattern:
    typeName '::' '{' structPatternField { ',' structPatternField } [ ',' ] '}'

structPatternField:
    fieldName
  | fieldName ':' pattern
```

```lane2
match value {
  Option::none => fallback
  Option::some(x) => x
}
```

Match arms use `pattern => expression`.

Every match must be exhaustive.

V1 patterns:

- wildcard pattern: `_`,
- variable binding pattern: `name`,
- literal pattern,
- qualified enum variant pattern,
- qualified struct pattern.

Enum variants in patterns must be qualified:

```lane2
Option::some(x)
Option::none
```

Bare identifiers in patterns are always variable bindings:

```lane2
match value {
  x => x
}
```

Struct patterns use qualified syntax and must list all fields:

```lane2
match p {
  Point::{ x, y } => x + y
}
```

Struct pattern punning is allowed. Explicit renaming is allowed:

```lane2
match p {
  Point::{ x: a, y: b } => a + b
}
```

Rest patterns, spread patterns, guards, or-patterns, as-patterns, and `is` pattern expressions are not supported in v1.

= Operators

Operators are aliases for recognized prelude operation fields.

There is no type-directed instance search. An operator is available only when the relevant operation field is available through preopen or an open scope extension.

Primitive operators are not special-cased. For example, `1 + 2` requires an available `Add::add` operation for `Int`.

Recognized operator mappings:

#figure(caption: [Recognized operator mappings])[
  #table(
    columns: (auto, 1fr),
    [Operator], [Operation],
    [`+`], [`Add::add`],
    [`-`], [`Sub::sub`],
    [`*`], [`Mul::mul`],
    [`/`], [`Div::div`],
    [`%`], [`Rem::rem`],
    [unary `-`], [`Neg::neg`],
    [`==`], [`Equal::equal`],
    [`!=`], [`Equal::not_equal`],
    [`<`], [`Compare::less`],
    [`<=`], [`Compare::less_eq`],
    [`>`], [`Compare::greater`],
    [`>=`], [`Compare::greater_eq`],
    [`&&`], [`And::and` with a thunked right operand],
    [`||`], [`Or::or` with a thunked right operand],
    [`!`], [`Not::not`],
  )
]

`&&` and `||` are short-circuit boolean operators. They are recognized mappings to `And::and` and `Or::or`, but the right operand is passed as a zero-argument function instead of being evaluated before the operation call.

`a && b` desugars to a call equivalent to `and(a, fn() { b })` after resolving an available `And::and` operation. `a || b` follows the same rule with `Or::or`. Both operators are defined only for `Bool`.

Concrete expression precedence, associativity, and unary/binary disambiguation follow the MoonBit parser reference where Lane2 has not deliberately removed a feature.

= Evaluation

Lane2 v1 is pure and strict.

- Evaluating a safe expression depends only on its inputs and produces a value.
- Function arguments are evaluated before the function body runs.
- `if` and `match` evaluate only the selected branch.
- There is no mutable binding, mutable field, assignment, field update, or implicit statement sequencing.
- IO and other effects are not part of v1 core semantics.

The `Unit` value is written explicitly as `()`.

Empty blocks are invalid. A block must contain exactly one final expression after any local items.

Function calls evaluate all arguments before entering the function body. The only v1 operator forms that delay a subexpression are `&&` and `||`, which pass the right operand as a thunk to the resolved prelude operation.

= Undefined Behavior

Incorrect builtin use can produce undefined behavior. Lane2's type safety guarantee applies only to programs that do not misuse `builtin`.

Invalid integer arithmetic is undefined behavior in v1. This includes signed 64-bit overflow, division by zero, remainder by zero, `MIN_INT / -1`, and negating `MIN_INT`.

= Conformance

The words "must", "must not", "may", and "should" are normative in this document.

Text marked as rationale, examples, or notes is informative unless it explicitly uses normative language.

An implementation conforms to this draft if it accepts all valid programs described here, rejects invalid programs described here, and gives the specified typing and evaluation behavior for safe programs.

Programs that misuse `builtin` are outside Lane2's safety guarantee.

= Appendix

== Deliberately Omitted From V1

V1 omits:

- mutation and assignment,
- field update and copy update,
- modules and imports,
- local type definitions,
- labeled function parameters,
- labeled enum payloads,
- type aliases,
- traits, typeclasses, interfaces,
- method syntax,
- tuple types,
- collections,
- pattern guards,
- or-patterns,
- as-patterns,
- `is` pattern expressions,
- placeholder pipeline.
