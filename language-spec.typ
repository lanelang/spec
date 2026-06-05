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

#let lane-source(path) = raw(read(path), block: true, lang: "lane2")

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

Design feedback is tracked in the Lane2 repository. Implementation changes should update this specification, `CONTEXT.md`, and ADRs when the change affects user-visible semantics.

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
  | "return"

identifier ::=
    asciiIdentifierStart identifierContinue*
  | "_" identifierContinue+

identifierContinue ::=
    "_"
  | asciiIdentifierStart
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

asciiIdentifierStart ::=
    asciiUppercaseLetter
  | asciiLowercaseLetter

asciiUppercaseLetter ::=
    any ASCII code point from U+0041 through U+005A

asciiLowercaseLetter ::=
    any ASCII code point from U+0061 through U+007A
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
  | topLevelOpenLetDeclaration
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

topLevelOpenLetDeclaration ::=
    "let" "open" valueName space ":" space type "=" expression

localLetDeclaration ::=
    "let" valueName typeAnnotation? "=" expression

localOpenLetDeclaration ::=
    "let" "open" valueName typeAnnotation? "=" expression

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
  | plainValueReference
  | qualifiedVariantExpression
  | structLiteral
  | builtinExpression
  | "(" expression ")"
  | "(" ")"

plainValueReference ::=
    "." valueName

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
  | localOpenLetDeclaration
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
    [$C #sym.arrow.r D #sym.in #sym.Delta$], [visible custom type definition binding],
    [$op("struct")(A_1, ..., A_n; l_1 : F_1, ..., l_m : F_m)$], [struct definition],
    [$op("enum")(A_1, ..., A_n; v_j(P_(j,1), ..., P_(j,m_j)))$], [enum definition],
    [$op("params")(D) = (A_1, ..., A_n)$], [custom type parameters],
    [$D #sym.tack.r v : (P_1, ..., P_m)$], [variant payload sequence declared by a custom type definition],
    [$D #sym.tack.r op("variants")(v_1, ..., v_q)$], [variant sequence declared by a custom type definition],
    [$#sym.Delta; #sym.Theta #sym.tack.r E[T_1, ..., T_n] "::" v #sym.arrow.r (Q_1, ..., Q_m)$], [instantiated variant payload sequence],
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
    [$op("arm-type")(E[T_1, ..., T_n], v, R)$], [typed enum match arm],
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

A generic function literal or named generic function introduces a generic function value. The function body is checked under the declared type parameters and value parameters.

#rule[
  $ #sym.Delta; #sym.Theta, A_1, ..., A_n #sym.tack.r (T_1, ..., T_m) -> R " type" quad #sym.Gamma, x_1 : T_1, ..., x_m : T_m #sym.tack.r e : R $
][
  $ #sym.Gamma #sym.tack.r op("fn")([A_1, ..., A_n], (x_1 : T_1), ..., (x_m : T_m), R, e) : #sym.forall A_1, ..., A_n "." (T_1, ..., T_m) -> R $
]

*Generic function elimination.*

Generic function calls instantiate type parameters at the use site when the use site is unambiguous.

```lane2
f(a1, ..., am) // generic function call with inferred type arguments
```

#rule[
  $ #sym.Gamma #sym.tack.r f : #sym.forall A_1, ..., A_n "." (T_1, ..., T_m) -> R quad #sym.sigma = [U_1 #sym.slash A_1, ..., U_n #sym.slash A_n] quad #sym.Gamma #sym.tack.r a_1 : T_1 #sym.sigma quad ... quad #sym.Gamma #sym.tack.r a_m : T_m #sym.sigma $
][
  $ #sym.Gamma #sym.tack.r f(a_1, ..., a_m) : R #sym.sigma $
]

The substitution #math.inline[$#sym.sigma$] must be the unique substitution selected by local type inference for the call site. If no unique substitution exists, the call is ill-typed.

*Generic function type equality.*

#rule[
  $ (T_1, ..., T_m) -> R #sym.eq.triple (U_1, ..., U_m) -> S $
][
  $ #sym.forall A_1, ..., A_n "." (T_1, ..., T_m) -> R #sym.eq.triple #sym.forall A_1, ..., A_n "." (U_1, ..., U_m) -> S $
]

Generic function type equality compares the number of type parameters and the function types under corresponding bound type parameters.

== Nominal Type Constructors

Struct and enum declarations introduce nominal custom type definitions in #sym.Delta. This section specifies the shared treatment of nominal type constructors. Struct-specific and enum-specific declaration rules are specified in "Struct Types" and "Enum Types".

Top-level custom type declarations are checked in two phases. First, all top-level struct and enum constructors are collected into #sym.Delta as declaration-shape bindings. Second, every field type and variant payload type is checked under the collected #sym.Delta and the declaration's type parameters. This permits mutually recursive custom types.

*Custom type collection.* A top-level custom type declaration contributes its nominal constructor and declaration shape to #sym.Delta before member type checking begins. In enum declaration shapes, #math.inline[$P_j$] denotes the payload type sequence of variant #math.inline[$v_j$].

```lane2
struct S[A1, ..., An] { l1 : F1, ..., lm : Fm }
enum E[A1, ..., An] { vj(Pj1, ..., Pjmj) }
```

$ S #sym.arrow.r op("struct")(A_1, ..., A_n; l_1 : F_1, ..., l_m : F_m) #sym.in #sym.Delta quad E #sym.arrow.r op("enum")(A_1, ..., A_n; v_1(P_1), ..., v_q(P_q)) #sym.in #sym.Delta $

*Nominal formation.* A nominal type application is well-formed when its custom type constructor is visible, the number of type arguments matches the declaration's type parameters, and every type argument is well-formed.

#rule[
  $ C #sym.arrow.r D #sym.in #sym.Delta quad op("params")(D) = (A_1, ..., A_n) quad #sym.Delta; #sym.Theta #sym.tack.r T_1 " type" quad ... quad #sym.Delta; #sym.Theta #sym.tack.r T_n " type" $
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

*Struct declaration well-formedness.* A struct declaration is well-formed when every declared field type is well-formed under the collected type-constructor context and the struct's type parameters.

```lane2
struct S[A1, ..., An] {
  l1 : F1
  ...
  lm : Fm
} // struct definition
```

$ frac(
  display(cases(
    #[$ S #sym.arrow.r op("struct")(A_1, ..., A_n; l_1 : F_1, ..., l_m : F_m) #sym.in #sym.Delta $],
    #[$ #sym.forall i "." #sym.Delta; A_1, ..., A_n #sym.tack.r F_i " type" $],
  )),
  #sym.Delta #sym.tack.r op("struct-decl")(S; A_1, ..., A_n; l_1 : F_1, ..., l_m : F_m) " declaration",
) $

*Struct introduction.* A qualified struct literal introduces a struct value. It must provide every declared field exactly once. Source field order is not significant; the rule below uses declaration order.

```lane2
S[T1, ..., Tn]::{ l1: e1, ..., lm: em } // qualified struct literal
```

#rule[
  $ S #sym.arrow.r op("struct")(A_1, ..., A_n; l_1 : F_1, ..., l_m : F_m) #sym.in #sym.Delta quad #sym.sigma = [T_1 #sym.slash A_1, ..., T_n #sym.slash A_n] $
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

*Enum declaration well-formedness.* An enum declaration is well-formed when every declared variant payload type is well-formed under the collected type-constructor context and the enum's type parameters.

```lane2
enum E[A1, ..., An] {
  v1(P11, ..., P1m1)
  ...
  vj(Pj1, ..., Pjmj)
} // enum definition
```

$ frac(
  display(cases(
    #[$ E #sym.arrow.r op("enum")(A_1, ..., A_n; v_1(P_1), ..., v_q(P_q)) #sym.in #sym.Delta $],
    #[$ #sym.forall j,k "." #sym.Delta; A_1, ..., A_n #sym.tack.r P_(j,k) " type" $],
  )),
  #sym.Delta #sym.tack.r op("enum-decl")(E; A_1, ..., A_n; v_1(P_1), ..., v_q(P_q)) " declaration",
) $

*Variant constructor introduction.* Each declared variant constructor is an introduction form for values of its owning enum type. A variant constructor does not introduce a separate variant type. The payload expressions must match the declared variant payload types after substituting the enum type arguments.

```lane2
E[T1, ..., Tn]::v(e1, ..., em) // qualified variant constructor call
v(e1, ..., em) // unqualified constructor call after unambiguous resolution
```

For an enum declaration shape #math.inline[$D$], #math.inline[$D #sym.tack.r v : (P_1, ..., P_m)$] states that #math.inline[$D$] declares variant #math.inline[$v$] with payload type sequence #math.inline[$(P_1, ..., P_m)$].

The judgment #math.inline[$#sym.Delta; #sym.Theta #sym.tack.r E[T_1, ..., T_n] "::" v #sym.arrow.r (Q_1, ..., Q_m)$] instantiates that payload sequence at the enum type arguments.

$ frac(
  display(cases(
    #[$ E #sym.arrow.r D #sym.in #sym.Delta $],
    #[$ D #sym.tack.r v : (P_1, ..., P_m) $],
    #[$ op("params")(D) = (A_1, ..., A_n) $],
    #[$ #sym.sigma = [T_1 #sym.slash A_1, ..., T_n #sym.slash A_n] $],
    #[$ #sym.forall i "." #sym.Delta; #sym.Theta #sym.tack.r T_i " type" $],
  )),
  #sym.Delta; #sym.Theta #sym.tack.r E[T_1, ..., T_n] "::" v #sym.arrow.r (P_1 #sym.sigma, ..., P_m #sym.sigma),
) $

$ frac(
  display(cases(
    #[$ #sym.Delta; #sym.Theta #sym.tack.r E[T_1, ..., T_n] "::" v #sym.arrow.r (Q_1, ..., Q_m) $],
    #[$ #sym.forall k "." #sym.Gamma #sym.tack.r e_k : Q_k $],
  )),
  #sym.Gamma #sym.tack.r op("variant")(E[T_1, ..., T_n], v, e_1, ..., e_m) : E[T_1, ..., T_n],
) $

An unqualified enum variant expression is typed by the same rule after name resolution has selected exactly one visible enum variant.

*Enum match elimination.* A match expression eliminates an enum value. For an enum scrutinee type, every declared variant must be covered.

```lane2
match e {
  E::v1(x11, ..., x1m1) => b1
  ...
  E::vq(xq1, ..., xqmq) => bq
}
```

$ frac(
  display(cases(
    #[$ #sym.Delta; #sym.Theta #sym.tack.r E[T_1, ..., T_n] "::" v #sym.arrow.r (Q_1, ..., Q_m) $],
    #[$ #sym.Gamma, x_1 : Q_1, ..., x_m : Q_m #sym.tack.r b : R $],
  )),
  #sym.Gamma #sym.tack.r op("arm")(v(x_1, ..., x_m) => b) : op("arm-type")(E[T_1, ..., T_n], v, R),
) $

$ frac(
  display(cases(
    #[$ #sym.Gamma #sym.tack.r e : E[T_1, ..., T_n] $],
    #[$ E #sym.arrow.r D #sym.in #sym.Delta $],
    #[$ D #sym.tack.r op("variants")(v_1, ..., v_q) $],
    #[$ #sym.forall j "." #sym.Gamma #sym.tack.r a_j : op("arm-type")(E[T_1, ..., T_n], v_j, R) $],
  )),
  #sym.Gamma #sym.tack.r op("match")(e; a_1, ..., a_q) : R,
) $

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

`%bool_and`, `%bool_or`, `%bool_not`, and `%bool_equal` are not required intrinsics. The standard prelude defines boolean operations as ordinary Lane2 functions and open bindings using `if`; `&&` and `||` supply their right operands as thunks.

= Prelude

The standard prelude is implementation-supplied Lane2 source checked before user code. It is not a module system.

Prelude declarations provide standard operation structs, primitive wrappers around required intrinsics, derived primitive operations written in Lane2, and prelude-provided open bindings that populate the initial preopen namespace.

Prelude entries are ordinary Lane2 values and types. Operation structs are API conventions that group ordinary operation names.

Operation laws are API conventions, not compiler-checked rules.

== Standard Prelude Source

The v1 standard prelude source is stored in `lane-std/prelude.lane` and rendered here:

#lane-source("../lane-std/prelude.lane")

Boolean conjunction, disjunction, negation, and equality do not require boolean intrinsics; they can be defined with ordinary `if` expressions in the prelude.

= Declarations

Declarations introduce types, functions, values, and open scope extensions.

== Top-Level Declarations

Top-level declarations are described by the `topLevelDefinition` grammar in "Syntax and Grammar".

Top-level forms include struct declarations, enum declarations, named function declarations, typed value declarations, open bindings, and open declarations.

== Struct Declarations

Struct declarations use the grammar in "Structs, Enums, and Open".

== Enum Declarations

Enum declarations use the grammar in "Structs, Enums, and Open".

== Function Declarations

Functions are uncurried. There is no automatic currying or partial application.

Function definitions use block bodies:

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

Named top-level `let` declarations must include type annotations.

Local `let` declarations may omit type annotations when their initializer can synthesize a type by local type inference.

An open binding has the form `let open name ... = expression`. It is syntax sugar for a value declaration immediately followed by `open name`.

Top-level open bindings must include type annotations because all top-level value declarations must include type annotations:

```lane2
let open int_ops : Add[Int] = Add::{ op_add: int_add }
```

Local open bindings may omit type annotations when their initializer can synthesize a unique struct type:

```lane2
{
  let open ops = Add::{ op_add: int_add }
  1 + 2
}
```

Open bindings are not forward-visible and are not recursively open.

= Scopes and Bindings

== Notations

#figure(caption: [Scope and binding notations])[
  #table(
    columns: (auto, 1fr),
    [Notation], [Meaning],
    [$R$], [resolution environment],
    [$#sym.Delta$], [type-name namespace],
    [$#sym.Gamma$], [ordinary value-binding scope stack],
    [$#sym.Omega$], [open-exposure scope stack],
    [$#sym.Pi$], [preopen exposure layer],
    [$s_T, s_V, s_F, s_R$], [type, value, field, and variant symbols],
    [$x$], [ordinary value name],
    [$C$], [type name],
    [$S$], [struct type constructor],
    [$E$], [enum type constructor],
    [$l$], [struct field name],
    [$v$], [enum variant name],
    [$K$], [direct local typing constraint],
    [$P$], [plain value candidate],
    [$O$], [open-exposure candidate set],
    [$Q$], [combined value candidate set],
    [$R = (#sym.Delta, #sym.Gamma, #sym.Omega, #sym.Pi)$], [resolution environment components],
    [$#sym.Delta #sym.tack.r C #sym.arrow.r s_T$], [type-name resolution],
    [$#sym.Gamma #sym.tack.r x #sym.arrow.r P$], [ordinary value resolution],
    [$#sym.Omega ";" #sym.Pi #sym.tack.r x #sym.arrow.r O$], [open and preopen resolution],
    [$R #sym.tack.r d #sym.arrow.r R'$], [declaration resolution],
    [$R ";" K #sym.tack.r e #sym.arrow.r s$], [expression-name resolution under a local typing constraint],
    [$op("select")(Q, K) = s_V$], [candidate selection by direct local typing],
    [$op("fields")(s_V) = (l_1 : s_(F,1), ..., l_n : s_(F,n))$], [fields exposed by opening a struct value],
    [$op("variant")(s_T, v) = s_R$], [variant owned by an enum type symbol],
  )
]

== Resolution Model

Name resolution maps source names to symbols or candidate sets before typed core is produced. It does not evaluate expressions. When an unqualified value reference denotes multiple candidates, local type checking may select exactly one candidate using direct local typing information; otherwise the reference is ambiguous.

The resolution environment has separate namespaces for type names and value names. Field and variant symbols are owned by nominal type symbols and are not global value bindings.

```lane2
// source names
TypeName
value_name
value_name.field_name
TypeName::variant_name
```

#math-list(
  $ R = (#sym.Delta, #sym.Gamma, #sym.Omega, #sym.Pi) $,
  $ #sym.Delta #sym.tack.r C #sym.arrow.r s_T $,
  $ R ";" K #sym.tack.r x #sym.arrow.r s_V $,
)

== Namespaces

Type and value names are resolved by different lookup judgments. The same source spelling may therefore be bound in both namespaces without conflict.

```lane2
enum Option[A] {
  none
  some(A)
}

let Option : Int = 42
```

*Type-name lookup.* A type name resolves through the type namespace.

#rule[
  $ C #sym.arrow.r s_T #sym.in #sym.Delta $
][
  $ #sym.Delta #sym.tack.r C #sym.arrow.r s_T $
]

*Ordinary value lookup.* A value name resolves through the ordinary value-binding scope stack.

#rule[
  $ x #sym.arrow.r s_V #sym.in #sym.Gamma $
][
  $ #sym.Gamma #sym.tack.r x #sym.arrow.r s_V $
]

Qualified type-member syntax resolves its left-hand side in the type namespace.

```lane2
Option::some(1) // Option is resolved as a type name
```

#rule[
  $ #sym.Delta #sym.tack.r E #sym.arrow.r s_T quad op("variant")(s_T, v) = s_R $
][
  $ R #sym.tack.r op("qualified-variant")(E, v) #sym.arrow.r s_R $
]

== Top-Level Scope

Top-level `struct`, `enum`, and `fn` declarations are collected before top-level value initializers are resolved. Top-level custom types and functions may therefore refer to each other regardless of textual order.

```lane2
struct S { value : T }
enum T { wrap(S) }
fn f(x : T) -> T { x }
```

#rule[
  $ op("types")(d_1, ..., d_n) = #sym.Delta quad op("functions")(d_1, ..., d_n) = #sym.Gamma $
][
  $ op("top-recursive")(d_1, ..., d_n) = (#sym.Delta, #sym.Gamma) $
]

Top-level value definitions and top-level `open` declarations are resolved in source order. A top-level `let` initializer may refer only to values available at that declaration point. A top-level function body is resolved after the complete top-level function and value environment is known.

```lane2
let x : Int = earlier
open x_ops
let open y_ops : Add[Int] = Add::{ op_add: int_add }
```

#rule[
  $ R_i ";" K_i #sym.tack.r e_i #sym.arrow.r e_i' quad R_(i+1) = R_i, x_i #sym.arrow.r s_i $
][
  $ R_i #sym.tack.r op("top-let")(x_i, T_i, e_i) #sym.arrow.r R_(i+1) $
]

#rule[
  $ R_i ";" K #sym.tack.r op("plain-ref")(x) #sym.arrow.r s_V quad R_(i+1) = R_i, op("open-fields")(s_V) $
][
  $ R_i #sym.tack.r op("open")(x) #sym.arrow.r R_(i+1) $
]

An open binding first binds the value, then opens that value from the declaration point forward.

```lane2
let open ops : Add[Int] = Add::{ op_add: int_add }
```

#rule[
  $ R_i #sym.tack.r op("top-let")(x, T, e) #sym.arrow.r R_j quad R_j ";" K #sym.tack.r op("plain-ref")(x) #sym.arrow.r s_V quad R_(j+1) = R_j, op("open-fields")(s_V) $
][
  $ R_i #sym.tack.r op("top-let-open")(x, T, e) #sym.arrow.r R_(j+1) $
]

== Local Scope

Local `let`, local named `fn`, and local `open` items are sequential. A local binding is visible only to later local items and the final expression in the same block.

```lane2
{
  let x = e
  fn f(y : T) -> U { b }
  open ops
  result
}
```

#rule[
  $ R_i ";" K_i #sym.tack.r e_i #sym.arrow.r e_i' quad R_(i+1) = R_i, x_i #sym.arrow.r s_i $
][
  $ R_i #sym.tack.r op("local-let")(x_i, e_i) #sym.arrow.r R_(i+1) $
]

#rule[
  $ R_(i+1) = R_i, f #sym.arrow.r s_f quad R_(i+1) ";" K #sym.tack.r b #sym.arrow.r b' $
][
  $ R_i #sym.tack.r op("local-fn")(f, U, b) #sym.arrow.r R_(i+1) $
]

Local value names may shadow earlier value names from outer layers. Ordinary value bindings in the same layer must have distinct names.

```lane2
let x = outer
{
  let x = inner
  x
}
```

#rule[
  $ #sym.Gamma = #sym.Gamma _0, (x #sym.arrow.r s_1) quad #sym.Gamma' = #sym.Gamma, (x #sym.arrow.r s_2) $
][
  $ #sym.Gamma' #sym.tack.r x #sym.arrow.r s_2 $
]

== Open Scope Extensions

`open x` requires `x` to resolve as a unique ordinary value binding. The operand is a value name, not an arbitrary expression.

```lane2
open ops
```

#rule[
  $ #sym.Gamma #sym.tack.r x #sym.arrow.r s_V quad op("type-of")(s_V) = S[T_1, ..., T_n] $
][
  $ (#sym.Delta, #sym.Gamma, #sym.Omega, #sym.Pi) #sym.tack.r op("open")(x) #sym.arrow.r s_V $
]

An opened value must have a struct type. Opening the value exposes direct fields and fields forwarded by struct declaration `open` entries. The exposure belongs to the current open layer.

```lane2
struct Compare[T] {
  equal_impl : Equal[T]
  open equal_impl
  op_less : (T, T) -> Bool
}

open compare_ops
```

#rule[
  $ R #sym.tack.r op("open")(x) #sym.arrow.r s_V quad op("fields")(s_V) = (l_1 : s_(F,1), ..., l_n : s_(F,n)) $
][
  $ R #sym.tack.r op("open-layer")(x) #sym.arrow.r (l_1 #sym.arrow.r s_(F,1), ..., l_n #sym.arrow.r s_(F,n)) $
]

Open exposure name repetition is not an error at the open declaration point. Repeated exposed names in the same open layer form a candidate set.

```lane2
open int_ops
open float_ops
op_add
```

#rule[
  $ #sym.Omega #sym.tack.r x #sym.arrow.r (s_1, ..., s_n) $
][
  $ #sym.Omega ";" #sym.Pi #sym.tack.r x #sym.arrow.r (s_1, ..., s_n) $
]

== Preopen

The preopen namespace is a default-open layer prepared by the prelude before user code is resolved. It exposes field values from prelude-provided open bindings.

```lane2
let open int_add_ops : Add[Int] = Add::{ op_add: int_add }
```

#rule[
  $ op("prelude-open-bindings") = (s_1, ..., s_n) quad op("fields")(s_i) = O_i $
][
  $ #sym.Pi = op("merge")(O_1, ..., O_n) $
]

Open layers shadow outer open layers and preopen. Ordinary value bindings and open exposures use separate shadowing.

```lane2
{
  open local_ops
  op_add
}
```

#rule[
  $ #sym.Omega #sym.tack.r x #sym.arrow.r O $
][
  $ #sym.Omega ";" #sym.Pi #sym.tack.r x #sym.arrow.r O $
]

#rule[
  $ #sym.Omega #sym.tack.r x #sym.arrow.r () quad #sym.Pi #sym.tack.r x #sym.arrow.r O $
][
  $ #sym.Omega ";" #sym.Pi #sym.tack.r x #sym.arrow.r O $
]

== Value References and Candidate Selection

An unqualified value reference combines the nearest ordinary value binding candidate with candidates exposed by the nearest applicable open layer.

```lane2
op_add
```

#rule[
  $ #sym.Gamma #sym.tack.r x #sym.arrow.r P quad #sym.Omega ";" #sym.Pi #sym.tack.r x #sym.arrow.r O $
][
  $ (#sym.Delta, #sym.Gamma, #sym.Omega, #sym.Pi) #sym.tack.r x #sym.arrow.r op("combine")(P, O) $
]

Candidate selection uses only direct local typing information: an expected type, function call argument count and argument checking, and generic instantiation determined by the same local information. Lane2 does not choose a default candidate.

```lane2
op_add(1, 2) // selected by call shape and argument types
```

#rule[
  $ R #sym.tack.r x #sym.arrow.r Q quad op("select")(Q, K) = s_V $
][
  $ R ";" K #sym.tack.r x #sym.arrow.r s_V $
]

#rule[
  $ R #sym.tack.r x #sym.arrow.r Q quad op("select")(Q, K) = op("ambiguous") $
][
  $ R ";" K #sym.tack.r x #sym.arrow.r op("error")("ambiguous") $
]

A plain value reference starts with `.` and excludes open and preopen exposures.

```lane2
.op_add
```

#rule[
  $ #sym.Gamma #sym.tack.r x #sym.arrow.r s_V $
][
  $ (#sym.Delta, #sym.Gamma, #sym.Omega, #sym.Pi) ";" K #sym.tack.r op("plain-ref")(x) #sym.arrow.r s_V $
]

== Special Resolution Forms

An unqualified enum variant expression may resolve without qualification only when candidate selection chooses exactly one visible variant.

```lane2
some(1)
```

#rule[
  $ op("variants-named")(#sym.Delta, v) = Q quad op("select")(Q, K) = s_R $
][
  $ (#sym.Delta, #sym.Gamma, #sym.Omega, #sym.Pi) ";" K #sym.tack.r op("variant-ref")(v) #sym.arrow.r s_R $
]

Field access first resolves and checks its base as a unique value, then selects a field owned by the base struct type.

```lane2
ops.op_add
```

#rule[
  $ R ";" K #sym.tack.r x #sym.arrow.r s_V quad op("type-of")(s_V) = S[T_1, ..., T_n] quad op("field")(S, l) = s_F $
][
  $ R ";" K #sym.tack.r op("field-access")(x, l) #sym.arrow.r s_F $
]

Operator aliases first map to fixed ordinary operation names, then use ordinary value lookup and candidate selection. `&&` and `||` add only right-operand thunking after the operation value has been resolved.

```lane2
a + b  // resolves through op_add
a && b // resolves through op_and, then thunks b
```

#rule[
  $ op("operator-name")(op) = x quad R ";" K #sym.tack.r x #sym.arrow.r s_V $
][
  $ R ";" K #sym.tack.r op("operator")(op) #sym.arrow.r s_V $
]

= Expressions

Expressions compute values. Lane2 v1 is expression-oriented and has no expression statements.

== Blocks

A block expression contains local items followed by one final expression.

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

An unqualified value reference may denote a candidate set. Candidate selection uses direct local typing information:

- a direct expected type, including expected result types for function bodies and branch expressions;
- function call argument count and argument checking against candidate parameter types;
- generic instantiation determined by the same direct local typing information.

Lane2 does not choose a default candidate. If more than one candidate remains applicable, the reference is ambiguous. Diagnostics for ambiguous candidates should list source-level disambiguation paths such as `.name` for an ordinary binding and `owner.field` for an opened field.

A plain value reference begins with `.` and resolves only ordinary lexical value bindings:

```lane2
.op_add
```

Plain value references still follow ordinary lexical shadowing among ordinary bindings, but exclude open and preopen exposures.

Function call:

```lane2
f(x, y)
```

Field access:

```lane2
ops.add
```

The base of field access must resolve and check as a unique value before field selection. Field access does not search through an unresolved candidate set for a base value.

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
  op_less : (T, T) -> Bool
  op_less_eq : (T, T) -> Bool
  op_greater : (T, T) -> Bool
  op_greater_eq : (T, T) -> Bool
}
```

When a value of this struct type is opened, forwarded fields are exposed too. Direct fields and forwarded fields from the same opened struct value contribute to the same open exposure layer.

Repeated exposed names are not conflicts at the open declaration point. Ambiguity is reported only at use sites when candidate selection cannot choose exactly one value.

Struct field forwarding affects only what is exposed by opening the containing struct value. It does not open the field inside ordinary function bodies.

= Pattern Matching

`match` is an expression:

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

Operators are aliases for fixed ordinary operation names.

There is no trait, typeclass, or instance search. An operator is available only when the corresponding operation name resolves to a suitable value through ordinary value lookup and open candidate selection.

Primitive operators are not special-cased. For example, `1 + 2` resolves through the ordinary name `op_add`; that name can be supplied by a normal binding or by opening a struct value with an `op_add` field.

Recognized operator mappings:

#figure(caption: [Recognized operator mappings])[
  #table(
    columns: (auto, 1fr),
    [Operator], [Operation name],
    [`+`], [`op_add`],
    [`-`], [`op_sub`],
    [`*`], [`op_mul`],
    [`/`], [`op_div`],
    [`%`], [`op_rem`],
    [unary `-`], [`op_neg`],
    [`==`], [`op_equal`],
    [`!=`], [`op_not_equal`],
    [`<`], [`op_less`],
    [`<=`], [`op_less_eq`],
    [`>`], [`op_greater`],
    [`>=`], [`op_greater_eq`],
    [`&&`], [`op_and` with a thunked right operand],
    [`||`], [`op_or` with a thunked right operand],
    [`!`], [`op_not`],
  )
]

Operation names such as `op_add` are ordinary value names, not reserved words. Lane2 v1 does not allow user-defined operator tokens or user-defined operator mappings.

`&&` and `||` are short-circuit boolean operators. They resolve through `op_and` and `op_or`, but the right operand is passed as a zero-argument function instead of being evaluated before the operation call.

`a && b` desugars to a call equivalent to `op_and(a, fn() { b })` after resolving an available `op_and` operation. `a || b` follows the same rule with `op_or`. Both operators are defined only for `Bool` in v1.

Ordinary calls to `op_and` and `op_or` are strict. Only the `&&` and `||` operator syntaxes thunk the right operand.

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

Function calls evaluate all arguments before entering the function body. The only v1 operator forms that delay a subexpression are `&&` and `||`, which pass the right operand as a thunk to the resolved `op_and` or `op_or` value.

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
