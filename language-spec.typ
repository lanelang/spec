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

Lane2 is intentionally small. It has no mutable state, assignment, trait system, method dispatch, module system, or implicit typeclass-style instance search in v1. Instead, v1 is centered on nominal data, first-class functions, bidirectional local type inference, exhaustive pattern matching, and contextual resolution of explicitly offered values.

This document specifies Lane2/Core v1: the platform-independent part of Lane2 that should behave the same across the initial AST interpreter and later execution backends.

== Scope

Lane2/Core v1 covers:

- source structure and declarations;
- lexical scope and name resolution;
- nominal struct and enum types, including existential type members and
  variant-local hidden type binders;
- function and block expressions;
- local type inference;
- pattern matching;
- contextual resolution and operation-based operators;
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
  | "auto"
  | "offer"
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
  | offerValueDeclaration

structDeclaration ::=
    "struct" typeName typeParameters? "{" structTypeMember* structFieldDeclaration* "}"

structTypeMember ::=
    "type" typeName space ":" space kind

structFieldDeclaration ::=
    fieldModifier? fieldName space ":" space type

fieldModifier ::=
    "offer"

enumDeclaration ::=
    "enum" typeName typeParameters? "{" enumVariant* "}"

enumVariant ::=
    variantName typeParameters? enumPayload?

enumPayload ::=
    "(" commaSeparatedTypes? ")"

functionDeclaration ::=
    "fn" typeParameters? functionName "(" commaSeparatedParameters? ")" "->" type block

parameter ::=
    parameterModifiers? valueName space ":" space type

parameterModifiers ::=
    parameterModifier+

parameterModifier ::=
    "auto"
  | "offer"

topLevelLetDeclaration ::=
    "let" valueName space ":" space type "=" expression

localLetDeclaration ::=
    "let" valueName typeAnnotation? "=" expression

localPatternLetDeclaration ::=
    "let" pattern "=" expression

typeAnnotation ::=
    space ":" space type

offerValueDeclaration ::=
    "offer" valueName space ":" space type "=" expression

type ::=
    typeConstructor typeArguments?
  | functionType

typeConstructor ::=
    typeName

typeArguments ::=
    "[" commaSeparatedTypes "]"

typeParameters ::=
    "[" commaSeparatedTypeParameters "]"

kind ::=
    "Type"
  | "Type" "->" kind
  | "(" kind ")"

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
    "(" commaSeparatedCallArguments? ")"

callArgument ::=
    expression
  | valueName "=" expression

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
    typeName typeArguments? "::" variantName variantTypeArguments? variantArguments?

variantTypeArguments ::=
    "[" commaSeparatedTypes "]"

variantArguments ::=
    "(" commaSeparatedExpressions? ")"

structLiteral ::=
    typeName typeArguments? "::" "{" commaSeparatedStructLiteralFields "}"

structLiteralField ::=
    fieldName
  | fieldName ":" expression
  | typeName "=" type

builtinExpression ::=
    "builtin" "(" stringLiteral ")"

functionLiteral ::=
    "fn" typeParameters? "(" commaSeparatedFunctionLiteralParameters? ")" functionReturnAnnotation? block

functionLiteralParameter ::=
    functionLiteralParameterModifiers? valueName
  | functionLiteralParameterModifiers? valueName space ":" space type

functionLiteralParameterModifiers ::=
    "offer"+

functionReturnAnnotation ::=
    "->" type

block ::=
    "{" localItem* expression "}"

localItem ::=
    localLetDeclaration
  | localPatternLetDeclaration
  | functionDeclaration
  | offerValueDeclaration

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
    typeName "::" variantName variantTypeBinders? patternArguments?

variantTypeBinders ::=
    "[" commaSeparatedTypeBinders "]"

patternArguments ::=
    "(" commaSeparatedPatterns? ")"

structPattern ::=
    typeName "::" "{" commaSeparatedStructPatternFields "}"

structPatternField ::=
    fieldName
  | typeName
  | "_"
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

commaSeparatedTypeBinders ::=
    typeBinder ("," typeBinder)* ","?

commaSeparatedParameters ::=
    parameter ("," parameter)* ","?

commaSeparatedExpressions ::=
    expression ("," expression)* ","?

commaSeparatedCallArguments ::=
    callArgument ("," callArgument)* ","?

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

typeBinder ::=
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
    [$A$], [universal type variable],
    [$B$], [existential type variable],
    [$K$], [kind],
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
    [$op("struct")(A_1, ..., A_n; B_1 : K_1, ..., B_r : K_r; l_1 : F_1, ..., l_m : F_m)$], [struct definition with universal parameters, existential type members, and value fields],
    [$op("enum")(A_1, ..., A_n; v_j[B_(j,1) : K_(j,1), ..., B_(j,r_j) : K_(j,r_j)](P_(j,1), ..., P_(j,m_j)))$], [enum definition with universal parameters and variant-local existential binders],
    [$op("params")(D) = (A_1, ..., A_n)$], [custom type parameters],
    [$D #sym.tack.r v : (B_1 : K_1, ..., B_r : K_r; P_1, ..., P_m)$], [variant hidden binders and payload sequence declared by a custom type definition],
    [$D #sym.tack.r op("variants")(v_1, ..., v_q)$], [variant sequence declared by a custom type definition],
    [$#sym.Delta; #sym.Theta #sym.tack.r E[T_1, ..., T_n] "::" v[U_1, ..., U_r] #sym.arrow.r (Q_1, ..., Q_m)$], [instantiated variant payload sequence],
    [$#sym.sigma$], [type substitution environment],
    [$#sym.sigma = [T_1 #sym.slash A_1, ..., T_n #sym.slash A_n]$], [substitution environment binding],
    [$#sym.rho = [U_1 #sym.slash B_1, ..., U_r #sym.slash B_r]$], [existential witness substitution],
    [$U[T_1 #sym.slash A_1, ..., T_n #sym.slash A_n]$], [direct type substitution],
    [$U #sym.sigma$], [type substitution by environment],
    [$#sym.Delta; #sym.Theta #sym.tack.r T " type"$], [well-formed type],
    [$C[T_1, ..., T_n]$], [nominal type application],
    [$#sym.forall A_1, ..., A_n "." T$], [universal type],
    [$#sym.exists B_1 : K_1, ..., B_r : K_r "." T$], [existential package model],
    [$T #sym.eq.triple U$], [type equality],
    [$#sym.Gamma #sym.tack.r e : T$], [expression typing],
    [$op("hidden-free")(T)$], [type that mentions no unopened existential binder],
    [$op("not-free")(B_1, ..., B_r; T)$], [none of the listed existential binders occurs free in type $T$],
    [$op("struct-shape")(S[T_1, ..., T_n]) = (B_1 : K_1, ..., B_r : K_r; l_1 : Q_1, ..., l_m : Q_m)$], [instantiated struct type members and value fields],
    [$op("arm-type")(E[T_1, ..., T_n], v, R)$], [typed enum match arm],
    [$frac(P, Q)$], [rule with premise $P$ and conclusion $Q$],
    [$op("name")$], [abstract syntax constructor],
  )
]

== Kinds

Lane2 v1 uses `Type` as the kind of ordinary value-level types. Type members carry explicit kinds so that the same surface form can later extend to higher-kinded witnesses.

*Kind formation.*

```lane2
Type
Type -> Type
```

#math-list(
  $ #sym.Delta; #sym.Theta #sym.tack.r "Type" " kind" $,
)

#rule[
  $ #sym.Delta; #sym.Theta #sym.tack.r K_1 " kind" quad #sym.Delta; #sym.Theta #sym.tack.r K_2 " kind" $
][
  $ #sym.Delta; #sym.Theta #sym.tack.r K_1 -> K_2 " kind" $
]

Declarations that use type members must record the written kind. `Type` is the first required kind, and function kinds such as `Type -> Type` are specified so existential type members are higher-kind-ready.

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

Top-level custom type declarations are checked in two phases. First, all top-level struct and enum constructors are collected into #sym.Delta as declaration-shape bindings. Second, every type member kind, field type, variant-local type binder kind, and variant payload type is checked under the collected #sym.Delta and the declaration's type parameters. This permits mutually recursive custom types.

*Custom type collection.* A top-level custom type declaration contributes its nominal constructor and declaration shape to #sym.Delta before member type checking begins. In struct declaration shapes, #math.inline[$B_1 : K_1, ..., B_r : K_r$] denotes hidden type members. In enum declaration shapes, #math.inline[$B_(j,1) : K_(j,1), ..., B_(j,r_j) : K_(j,r_j)$] denotes variant-local hidden type binders, and #math.inline[$P_j$] denotes the payload type sequence of variant #math.inline[$v_j$].

```lane2
struct S[A1, ..., An] {
  type B1 : K1
  ...
  l1 : F1
  ...
  lm : Fm
}

enum E[A1, ..., An] {
  vj[Bj1, ..., Bjrj](Pj1, ..., Pjmj)
}
```

$ S #sym.arrow.r op("struct")(A_1, ..., A_n; B_1 : K_1, ..., B_r : K_r; l_1 : F_1, ..., l_m : F_m) #sym.in #sym.Delta $

$ E #sym.arrow.r op("enum")(A_1, ..., A_n; v_1[B_(1,1) : K_(1,1), ..., B_(1,r_1) : K_(1,r_1)](P_1), ..., v_q[B_(q,1) : K_(q,1), ..., B_(q,r_q) : K_(q,r_q)](P_q)) #sym.in #sym.Delta $

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

Existential type members and variant-local binders are not arguments of the nominal type constructor. They do not participate in nominal type equality; their witnesses are hidden inside constructed values and can be opened only by pattern-based elimination.

== Existential Packages

Lane2 surface structs and enum variants with hidden type binders are modeled by existential packages. The existential type form is a static model used by the specification; Lane2 source does not provide a general `exists` type syntax.

*Existential formation.*

#rule[
  $ #sym.Delta; #sym.Theta, B_1 : K_1, ..., B_r : K_r #sym.tack.r T " type" $
][
  $ #sym.Delta; #sym.Theta #sym.tack.r #sym.exists B_1 : K_1, ..., B_r : K_r "." T " type" $
]

*Existential introduction.*

```lane2
Hide::{ T = Int, val: 5 } // struct package
Hide::hide[Int](5)        // enum variant package
```

#rule[
  $ #sym.Delta; #sym.Theta #sym.tack.r U_1 : K_1 quad ... quad #sym.Delta; #sym.Theta #sym.tack.r U_r : K_r quad #sym.rho = [U_1 #sym.slash B_1, ..., U_r #sym.slash B_r] quad #sym.Gamma #sym.tack.r v : T #sym.rho $
][
  $ #sym.Gamma #sym.tack.r op("pack")([U_1, ..., U_r], v) : #sym.exists B_1 : K_1, ..., B_r : K_r "." T $
]

*Existential elimination.*

```lane2
let Hide::{ T, val } = h
match h {
  Hide::hide[T](val) => body
}
```

#rule[
  $ #sym.Gamma #sym.tack.r e : #sym.exists B : K "." T quad #sym.Gamma, B : K, x : T #sym.tack.r b : R quad op("not-free")(B; R) $
][
  $ #sym.Gamma #sym.tack.r op("unpack")(e; B, x => b) : R $
]

The side condition prevents an opened hidden type from escaping the scope that opened it. A value whose type mentions an opened hidden type must be repacked into another existential before leaving that scope.

== Struct Types

*Struct declaration well-formedness.* A struct declaration is well-formed when every declared type member kind is well-formed and every declared field type is well-formed under the collected type-constructor context, the struct's universal type parameters, and the struct's hidden type members. Type members must appear before value fields in source.

```lane2
struct S[A1, ..., An] {
  type B1 : K1
  ...
  l1 : F1
  ...
  lm : Fm
} // struct definition
```

$ frac(
  display(cases(
    #[$ S #sym.arrow.r op("struct")(A_1, ..., A_n; B_1 : K_1, ..., B_r : K_r; l_1 : F_1, ..., l_m : F_m) #sym.in #sym.Delta $],
    #[$ #sym.forall p "." #sym.Delta; A_1, ..., A_n #sym.tack.r K_p " kind" $],
    #[$ #sym.forall i "." #sym.Delta; A_1, ..., A_n, B_1 : K_1, ..., B_r : K_r #sym.tack.r F_i " type" $],
  )),
  #sym.Delta #sym.tack.r op("struct-decl")(S; A_1, ..., A_n; B_1 : K_1, ..., B_r : K_r; l_1 : F_1, ..., l_m : F_m) " declaration",
) $

*Struct introduction.* A qualified struct literal introduces a struct value. It must provide every declared type-member witness and every declared value field exactly once. Source order is not significant for named witnesses and fields; the rule below uses declaration order.

```lane2
S[T1, ..., Tn]::{ l1: e1, ..., lm: em } // qualified struct literal
Hide::{ B1 = U1, val: e } // qualified struct literal with hidden type witness
```

#rule[
  $ S #sym.arrow.r op("struct")(A_1, ..., A_n; B_1 : K_1, ..., B_r : K_r; l_1 : F_1, ..., l_m : F_m) #sym.in #sym.Delta quad #sym.sigma = [T_1 #sym.slash A_1, ..., T_n #sym.slash A_n] $
][
  $ op("struct-shape")(S[T_1, ..., T_n]) = (B_1 : K_1 #sym.sigma, ..., B_r : K_r #sym.sigma; l_1 : F_1 #sym.sigma, ..., l_m : F_m #sym.sigma) $
]

$ frac(
  display(cases(
    #[$ op("struct-shape")(S[T_1, ..., T_n]) = (B_1 : K_1, ..., B_r : K_r; l_1 : Q_1, ..., l_m : Q_m) $],
    #[$ #sym.forall p "." #sym.Delta; #sym.Theta #sym.tack.r U_p : K_p $],
    #[$ #sym.rho = [U_1 #sym.slash B_1, ..., U_r #sym.slash B_r] $],
    #[$ #sym.forall i "." #sym.Gamma #sym.tack.r e_i : Q_i #sym.rho $],
  )),
  #sym.Gamma #sym.tack.r op("struct-lit")(S[T_1, ..., T_n], B_1 = U_1, ..., B_r = U_r, l_1 = e_1, ..., l_m = e_m) : S[T_1, ..., T_n],
) $

*Struct field elimination.* Field access eliminates a struct value by selecting a declared field type after substituting the struct type arguments. Field access alone does not open hidden type members. Therefore the selected field type must not mention unopened hidden type members.

```lane2
e.l // field access
```

#rule[
  $ #sym.Gamma #sym.tack.r e : S[T_1, ..., T_n] quad op("struct-shape")(S[T_1, ..., T_n]) = (B_1 : K_1, ..., B_r : K_r; ..., l : Q, ...) quad op("hidden-free")(Q) $
][
  $ #sym.Gamma #sym.tack.r e.l : Q $
]

*Struct pattern elimination.* A struct pattern may open hidden type members and bind value fields. The opened type binders are abstract and are available only in the scope governed by the pattern.

```lane2
let S::{ B1, ..., Br, l1: x1, ..., lm: xm } = e
```

$ frac(
  display(cases(
    #[$ #sym.Gamma #sym.tack.r e : S[T_1, ..., T_n] $],
    #[$ op("struct-shape")(S[T_1, ..., T_n]) = (B_1 : K_1, ..., B_r : K_r; l_1 : Q_1, ..., l_m : Q_m) $],
    #[$ #sym.Gamma, B_1 : K_1, ..., B_r : K_r, x_1 : Q_1, ..., x_m : Q_m #sym.tack.r b : R $],
    #[$ op("not-free")(B_1, ..., B_r; R) $],
  )),
  #sym.Gamma #sym.tack.r op("struct-unpack")(e; B_1, ..., B_r; x_1, ..., x_m => b) : R,
) $

Struct pattern syntax and contextual forwarding fields are specified in "Pattern Matching" and "Structs and Enums".

== Enum Types

*Enum declaration well-formedness.* An enum declaration is well-formed when every variant-local type binder kind is well-formed and every declared variant payload type is well-formed under the collected type-constructor context, the enum's type parameters, and the variant-local hidden type binders.

```lane2
enum E[A1, ..., An] {
  v1[B11, ..., B1r1](P11, ..., P1m1)
  ...
  vj[Bj1, ..., Bjrj](Pj1, ..., Pjmj)
} // enum definition
```

$ frac(
  display(cases(
    #[$ E #sym.arrow.r op("enum")(A_1, ..., A_n; v_j[B_(j,1) : K_(j,1), ..., B_(j,r_j) : K_(j,r_j)](P_(j,1), ..., P_(j,m_j))) #sym.in #sym.Delta $],
    #[$ #sym.forall j,p "." #sym.Delta; A_1, ..., A_n #sym.tack.r K_(j,p) " kind" $],
    #[$ #sym.forall j,k "." #sym.Delta; A_1, ..., A_n, B_(j,1) : K_(j,1), ..., B_(j,r_j) : K_(j,r_j) #sym.tack.r P_(j,k) " type" $],
  )),
  #sym.Delta #sym.tack.r op("enum-decl")(E; A_1, ..., A_n; v_j[B_(j,1) : K_(j,1), ..., B_(j,r_j) : K_(j,r_j)](P_j)) " declaration",
) $

*Variant constructor introduction.* Each declared variant constructor is an introduction form for values of its owning enum type. A variant constructor does not introduce a separate variant type. The payload expressions must match the declared variant payload types after substituting the enum type arguments.

```lane2
E[T1, ..., Tn]::v(e1, ..., em) // qualified variant constructor call
E[T1, ..., Tn]::v[U1, ..., Ur](e1, ..., em) // constructor call with hidden witnesses
v(e1, ..., em) // unqualified constructor call after unambiguous resolution
```

For an enum declaration shape #math.inline[$D$], #math.inline[$D #sym.tack.r v : (B_1 : K_1, ..., B_r : K_r; P_1, ..., P_m)$] states that #math.inline[$D$] declares variant #math.inline[$v$] with hidden type binders and payload type sequence #math.inline[$(P_1, ..., P_m)$].

The judgment #math.inline[$#sym.Delta; #sym.Theta #sym.tack.r E[T_1, ..., T_n] "::" v [U_1, ..., U_r] #sym.arrow.r (Q_1, ..., Q_m)$] instantiates that payload sequence at the enum type arguments and the chosen hidden witnesses.

$ frac(
  display(cases(
    #[$ E #sym.arrow.r D #sym.in #sym.Delta $],
    #[$ D #sym.tack.r v : (B_1 : K_1, ..., B_r : K_r; P_1, ..., P_m) $],
    #[$ op("params")(D) = (A_1, ..., A_n) $],
    #[$ #sym.sigma = [T_1 #sym.slash A_1, ..., T_n #sym.slash A_n] $],
    #[$ #sym.forall i "." #sym.Delta; #sym.Theta #sym.tack.r T_i " type" $],
    #[$ #sym.forall p "." #sym.Delta; #sym.Theta #sym.tack.r U_p : K_p #sym.sigma $],
    #[$ #sym.rho = [U_1 #sym.slash B_1, ..., U_r #sym.slash B_r] $],
  )),
  #sym.Delta; #sym.Theta #sym.tack.r E[T_1, ..., T_n] "::" v[U_1, ..., U_r] #sym.arrow.r (P_1 #sym.sigma #sym.rho, ..., P_m #sym.sigma #sym.rho),
) $

$ frac(
  display(cases(
    #[$ #sym.Delta; #sym.Theta #sym.tack.r E[T_1, ..., T_n] "::" v[U_1, ..., U_r] #sym.arrow.r (Q_1, ..., Q_m) $],
    #[$ #sym.forall k "." #sym.Gamma #sym.tack.r e_k : Q_k $],
  )),
  #sym.Gamma #sym.tack.r op("variant")(E[T_1, ..., T_n], v, [U_1, ..., U_r], e_1, ..., e_m) : E[T_1, ..., T_n],
) $

An unqualified enum variant expression is typed by the same rule after name resolution has selected exactly one visible enum variant. Variant-local hidden witnesses may be written explicitly after the variant name or selected by local type inference when there is exactly one solution.

*Enum match elimination.* A match expression eliminates an enum value. For an enum scrutinee type, every declared variant must be covered.

```lane2
match e {
  E::v1[B11, ..., B1r1](x11, ..., x1m1) => b1
  ...
  E::vq[Bq1, ..., Bqrq](xq1, ..., xqmq) => bq
}
```

$ frac(
  display(cases(
    #[$ E #sym.arrow.r D #sym.in #sym.Delta $],
    #[$ op("params")(D) = (A_1, ..., A_n) $],
    #[$ D #sym.tack.r v : (B_1 : K_1, ..., B_r : K_r; P_1, ..., P_m) $],
    #[$ #sym.sigma = [T_1 #sym.slash A_1, ..., T_n #sym.slash A_n] $],
    #[$ #sym.Gamma, B_1 : K_1 #sym.sigma, ..., B_r : K_r #sym.sigma, x_1 : P_1 #sym.sigma, ..., x_m : P_m #sym.sigma #sym.tack.r b : R $],
    #[$ op("not-free")(B_1, ..., B_r; R) $],
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

`%bool_and`, `%bool_or`, `%bool_not`, and `%bool_equal` are not required intrinsics. The standard prelude defines boolean operations as ordinary Lane2 functions and offered operation values using `if`; `&&` and `||` supply their right operands as thunks.

= Prelude

The standard prelude is implementation-supplied Lane2 source checked before user code. It is not a module system.

Prelude declarations provide standard operation structs, primitive wrappers around required intrinsics, derived primitive operations written in Lane2, and prelude-provided contextual offers.

Prelude entries are ordinary Lane2 values and types. Operation structs are API conventions that group short operation fields such as `add`, `equal`, and `less`.

Operation laws are API conventions, not compiler-checked rules.

== Standard Prelude Source

The v1 standard prelude source is stored in `lane-std/prelude.lane` and rendered here:

#lane-source("../lane-std/prelude.lane")

Boolean conjunction, disjunction, negation, and equality do not require boolean intrinsics; they can be defined with ordinary `if` expressions in the prelude.

= Declarations

Declarations introduce types, functions, values, and contextual offers.

== Top-Level Declarations

Top-level declarations are described by the `topLevelDefinition` grammar in "Syntax and Grammar".

Top-level forms include struct declarations, enum declarations, named function declarations, typed value declarations, and offered value definitions.

== Struct Declarations

Struct declarations use the grammar in "Structs and Enums".

== Enum Declarations

Enum declarations use the grammar in "Structs and Enums".

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

Named function definitions may mark a trailing suffix of parameters with `auto`. These contextual parameters remain ordinary parameters in the function type, but a direct named call may omit them and let Contextual Resolution supply them.

```lane2
fn[T] op_add(a : T, b : T, auto op : Add[T]) -> T {
  op.add(a, b)
}
```

Contextual parameters must appear as a contiguous suffix of the parameter list. Function literals cannot declare `auto` parameters.

A parameter may be marked `offer`; it is then added to the function body's contextual offer environment. The `offer` modifier does not affect the function type or call syntax. Function literals may use `offer` parameters.

```lane2
fn[T] twice(x : T, auto offer add : Add[T]) -> T {
  op_add(x, x)
}
```

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

An offered value definition has the form `offer name : Type = expression`. It defines a named value and immediately adds that value to the contextual offer environment.

Offered value definitions must include type annotations:

```lane2
offer int_add_ops : Add[Int] = Add::{ add: int_add }
```

Local offered value definitions use the same annotated form:

```lane2
{
  offer ops : Add[Int] = Add::{ add: int_add }
  1 + 2
}
```

Offered value definitions must be named. They are not forward-visible and do not make the defined value available as an offer inside its own initializer.

= Scopes and Bindings

== Notations

#figure(caption: [Scope and binding notations])[
  #table(
    columns: (auto, 1fr),
    [Notation], [Meaning],
    [$R$], [resolution environment],
    [$#sym.Delta$], [type-name namespace],
    [$#sym.Gamma$], [ordinary value-binding scope stack],
    [$#sym.Omega$], [contextual offer scope stack],
    [$s_T, s_V, s_F, s_R$], [type, value, field, and variant symbols],
    [$x$], [ordinary value name],
    [$C$], [type name],
    [$S$], [struct type constructor],
    [$E$], [enum type constructor],
    [$B$], [existential type binder],
    [$l$], [struct field name],
    [$v$], [enum variant name],
    [$A$], [contextual parameter target type],
    [$R = (#sym.Delta, #sym.Gamma, #sym.Omega)$], [resolution environment components],
    [$#sym.Delta #sym.tack.r C #sym.arrow.r s_T$], [type-name resolution],
    [$#sym.Gamma #sym.tack.r x #sym.arrow.r s_V$], [ordinary value resolution],
    [$#sym.Omega #sym.tack.r A #sym.arrow.r s_V$], [contextual resolution by type],
    [$R #sym.tack.r d #sym.arrow.r R'$], [declaration resolution],
    [$R #sym.tack.r e #sym.arrow.r e'$], [expression-name resolution],
    [$op("type-of")(s_V) = A$], [known type of a value symbol],
    [$op("forward")(s_V)$], [contextual offers forwarded from a struct value],
    [$op("variant")(s_T, v) = s_R$], [variant owned by an enum type symbol],
  )
]

== Resolution Model

Name resolution maps source names to symbols before Buslane Core Language is produced. It does not evaluate expressions. Contextual Resolution is a later type-directed step that supplies omitted contextual arguments from visible offers after ordinary call inference has determined the target contextual parameter types.

The resolution environment has separate namespaces for type names, value names, and contextual offers. Field and variant symbols are owned by nominal type symbols and are not global value bindings.

```lane2
// source names
TypeName
value_name
value_name.field_name
TypeName::variant_name
```

#math-list(
  $ R = (#sym.Delta, #sym.Gamma, #sym.Omega) $,
  $ #sym.Delta #sym.tack.r C #sym.arrow.r s_T $,
  $ #sym.Gamma #sym.tack.r x #sym.arrow.r s_V $,
  $ #sym.Omega #sym.tack.r A #sym.arrow.r s_V $,
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

Ordinary value lookup never searches the contextual offer environment.

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

Top-level value definitions and top-level offered value definitions are resolved in source order. A top-level initializer may refer only to values and contextual offers available at that declaration point. A top-level function body is resolved after the complete top-level function, value, and contextual offer environments are known.

```lane2
let x : Int = earlier
offer y_ops : Add[Int] = Add::{ add: int_add }
```

#rule[
  $ R_i ";" K_i #sym.tack.r e_i #sym.arrow.r e_i' quad R_(i+1) = R_i, x_i #sym.arrow.r s_i $
][
  $ R_i #sym.tack.r op("top-let")(x_i, T_i, e_i) #sym.arrow.r R_(i+1) $
]

An offered value definition checks its initializer with the current environment, defines the named value, and offers that value from the declaration point forward.

```lane2
offer ops : Add[Int] = Add::{ add: int_add }
```

#rule[
  $ R_i ";" K_i #sym.tack.r e #sym.arrow.r e' quad R_(i+1) = R_i, x #sym.arrow.r s_V, op("offer")(s_V) $
][
  $ R_i #sym.tack.r op("top-offer-value")(x, T, e) #sym.arrow.r R_(i+1) $
]

Top-level value initializers are checked only with contextual offers available earlier in source order. Top-level function bodies are checked with the complete top-level contextual offer environment.

== Local Scope

Local `let`, local named `fn`, and local offered value definitions are sequential. A local binding is visible only to later local items and the final expression in the same block.

```lane2
{
  let x = e
  fn f(y : T) -> U { b }
  offer ops : Add[Int] = Add::{ add: int_add }
  result
}
```

#rule[
  $ R_i ";" K_i #sym.tack.r e_i #sym.arrow.r e_i' quad R_(i+1) = R_i, x_i #sym.arrow.r s_i $
][
  $ R_i #sym.tack.r op("local-let")(x_i, e_i) #sym.arrow.r R_(i+1) $
]

A local pattern `let` is sequential and may introduce both value binders and type binders. It is the source form used to open existential structs over the remainder of the block.

```lane2
{
  let Hide::{ T, val } = h
  body
}
```

#rule[
  $ R_i ";" K_i #sym.tack.r e_i #sym.arrow.r e_i' quad op("pattern-binders")(p, e_i') = (B_1, ..., B_r; x_1 #sym.arrow.r s_1, ..., x_m #sym.arrow.r s_m) quad R_(i+1) = R_i, B_1, ..., B_r, x_1 #sym.arrow.r s_1, ..., x_m #sym.arrow.r s_m $
][
  $ R_i #sym.tack.r op("local-pattern-let")(p, e_i) #sym.arrow.r R_(i+1) $
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

== Contextual Offers

An offered value definition introduces a named value with an explicit type annotation and contributes that value to Contextual Resolution.

```lane2
offer int_add_ops : Add[Int] = Add::{ add: int_add }
```

#rule[
  $ #sym.Gamma #sym.tack.r x #sym.arrow.r s_V quad op("type-of")(s_V) = A $
][
  $ (#sym.Delta, #sym.Gamma, #sym.Omega) #sym.tack.r op("offer-value")(x) #sym.arrow.r (A #sym.arrow.r s_V), op("forward")(s_V) $
]

A contextual offer affects only Contextual Resolution. It does not expose fields as unqualified names.

```lane2
offer int_add_ops : Add[Int] = Add::{ add: int_add }
1 + 2
```

Multiple visible offers may have the same type. This is not an error at the offered value definition point. Ambiguity is reported only when Contextual Resolution needs a unique value of that type.

```lane2
offer left_add : Add[Int] = Add::{ add: int_add }
offer right_add : Add[Int] = Add::{ add: alternate_int_add }
1 + 2 // ambiguous if both offers have type Add[Int]
```

#rule[
  $ #sym.Omega #sym.tack.r A #sym.arrow.r (s_1, ..., s_n) quad n = 1 $
][
  $ #sym.Omega #sym.tack.r op("contextual")(A) #sym.arrow.r s_1 $
]

#rule[
  $ #sym.Omega #sym.tack.r A #sym.arrow.r () $
][
  $ #sym.Omega #sym.tack.r op("contextual")(A) #sym.arrow.r op("error")("missing-offer") $
]

#rule[
  $ #sym.Omega #sym.tack.r A #sym.arrow.r (s_1, ..., s_n) quad n > 1 $
][
  $ #sym.Omega #sym.tack.r op("contextual")(A) #sym.arrow.r op("error")("ambiguous-offer") $
]

Repeating the same offer identity is semantically idempotent but should produce a warning. Contextual offer deduplication uses offer identity, not runtime value equality.

Visible contextual offers from nested lexical scopes are combined rather than shadowed. Nested local function bodies can see contextual offers from their lexical environment.

== Contextual Forwarding Fields

When a value is offered, fields declared with the `offer` modifier are offered recursively. Forwarding contributes only to Contextual Resolution and never to ordinary value lookup.

```lane2
struct Compare[T] {
  offer equal_impl : Equal[T]
  less : (T, T) -> Bool
}

offer int_compare_ops : Compare[Int] = Compare::{ equal_impl, less: int_less }
```

Offering `int_compare_ops : Compare[Int]` also offers `int_compare_ops.equal_impl : Equal[Int]`. Forwarding uses normal nominal field typing of the containing value. Recursive forwarding must detect cycles.

#rule[
  $ op("type-of")(s_V) = S[T_1, ..., T_n] quad op("offered-fields")(S[T_1, ..., T_n]) = (l_1 : A_1, ..., l_m : A_m) $
][
  $ op("forward")(s_V) = (A_1 #sym.arrow.r s_V.l_1, ..., A_m #sym.arrow.r s_V.l_m), op("forward")(s_V.l_1), ..., op("forward")(s_V.l_m) $
]

== Direct Named Calls and Contextual Arguments

A function introduced by a named function definition may declare contextual parameters with `auto`. They must form a contiguous suffix of the parameter list. A contextual parameter remains an ordinary parameter in the function type.

```lane2
fn[T] op_add(a : T, b : T, auto op : Add[T]) -> T {
  op.add(a, b)
}
```

A direct named function call is a call whose callee is a direct value reference to a function definition symbol. Only direct named function calls may omit contextual parameters or use explicit contextual arguments. Calls through ordinary function values must provide every argument positionally according to the function type.

```lane2
op_add(1, 2)
op_add(1, 2, op=custom_add)
```

Explicit contextual arguments are named. Positional call arguments cannot fill contextual parameters.

```lane2
op_add(1, 2, custom_add) // invalid
```

The right-hand side of an explicit contextual argument is an ordinary expression. Explicit contextual arguments participate in ordinary generic call inference before Contextual Resolution supplies the remaining omitted contextual parameters.

Contextual Resolution never infers generic type arguments for the call being completed. It runs only after ordinary positional arguments, explicit contextual arguments, and the direct expected result type have determined the target contextual parameter types.

== Special Resolution Forms

An unqualified enum variant expression may resolve without qualification only when exactly one visible enum variant has that name.

```lane2
some(1)
```

#rule[
  $ op("variants-named")(#sym.Delta, v) = (s_R) $
][
  $ R ";" K #sym.tack.r op("variant-ref")(v) #sym.arrow.r s_R $
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

Operator aliases first map to fixed ordinary operation names, then elaborate to direct named calls when the operation name resolves to a function definition symbol. `&&` and `||` additionally thunk the right operand before the call is checked.

```lane2
a + b  // elaborates to op_add(a, b)
a && b // elaborates to op_and(a, fn() { b })
```

#rule[
  $ op("operator-name")(op) = x quad #sym.Gamma #sym.tack.r x #sym.arrow.r s_V $
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
- `offer`.

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

A direct named function call may omit trailing contextual parameters declared with `auto`. The omitted parameters are supplied by Contextual Resolution after ordinary argument checking and generic call inference determine their target types.

```lane2
op_add(1, 2)
```

A caller may explicitly supply contextual parameters by name:

```lane2
op_add(1, 2, op=custom_add)
```

Named call arguments are valid only for contextual parameters of direct named function calls. Non-contextual parameters cannot be supplied by name, and contextual parameters cannot be supplied positionally.

Field access:

```lane2
ops.add
```

The base of field access must resolve and check as a unique value before field selection.

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

= Structs and Enums

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

Structs may declare hidden type members before value fields:

```lane2
struct Hide {
  type T : Type
  val : T
}
```

Hidden type members are not ordinary value fields and are not accessed with dot syntax. Construction supplies type-member witnesses with `=` and value fields with `:`:

```lane2
let h : Hide = Hide::{ T = Int, val: 5 }
```

Consumers do not see the chosen witness type until a struct pattern opens it:

```lane2
let Hide::{ T, val } = h
```

After this local item, `T : Type` and `val : T` are available for the remaining local scope. The opened type `T` must not escape that scope unless it is packed again into an existential value.

Type members may be ignored with `_` in the type-member position of a struct pattern:

```lane2
let Hide::{ _, val } = h
```

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

If a field type mentions an unopened hidden type member, field access is invalid until a struct pattern has opened that hidden type.

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

An enum variant may declare hidden type binders that are chosen at construction and opened by matching the variant pattern:

```lane2
enum Hide {
  hide[T](T)
}

let h : Hide = Hide::hide[Int](5)

match h {
  Hide::hide[T](val) => body
}
```

Inside the arm, `T : Type` and `val : T` are available. The opened type `T` is abstract and must not escape the arm result type unless it is packed again into an existential value.

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

== Contextual Forwarding Fields

A struct field may be marked with `offer`:

```lane2
struct Compare[T] {
  offer equal_impl : Equal[T]
  less : (T, T) -> Bool
  less_eq : (T, T) -> Bool
  greater : (T, T) -> Bool
  greater_eq : (T, T) -> Bool
}
```

When a value of this struct type is offered, contextual forwarding fields are also offered. The forwarded field type is obtained by ordinary nominal field typing of the containing value.

```lane2
offer int_compare_ops : Compare[Int] = Compare::{ equal_impl, less: int_less }
```

If `int_compare_ops : Compare[Int]`, the offered value definition contributes both `Compare[Int]` and `Equal[Int]` offers: the latter is the field path `int_compare_ops.equal_impl`.

Contextual forwarding fields do not expose unqualified field names. They affect only Contextual Resolution. Forwarding is recursive and must detect cycles.

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
- qualified enum variant pattern, optionally with hidden type binders,
- qualified struct pattern.

Enum variants in patterns must be qualified:

```lane2
Option::some(x)
Option::none
Hide::hide[T](val)
```

When a variant declares hidden type binders, the variant pattern opens fresh abstract type binders for the arm body. The arm result type must not mention those binders.

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

Struct patterns for structs with type members list type-member binders before value fields. A type-member binder introduces an abstract type for the remaining local scope or match arm. `_` ignores one type member and does not introduce a usable type name.

```lane2
let Hide::{ T, val } = h
let Hide::{ _, val } = h
```

Hidden type binders opened by enum or struct patterns are scoped to the pattern body. They must not occur free in the type of the body result unless the value is repacked into another existential before leaving that body.

Rest patterns, spread patterns, guards, or-patterns, as-patterns, and `is` pattern expressions are not supported in v1.

= Operators

Operators are aliases for fixed ordinary operation names.

There is no trait, typeclass, or general instance search. An operator is available when the corresponding operation name resolves to a direct named function call whose non-contextual arguments and contextual parameters can be checked.

Primitive operators are not special-cased. For example, `1 + 2` elaborates through the ordinary name `op_add`; the standard prelude defines `op_add` as a generic named function with an `auto` operation parameter.

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

Operation names such as `op_add` are ordinary value names, not reserved words. User code may define them subject to ordinary binding uniqueness. Lane2 v1 does not allow user-defined operator tokens or user-defined operator mappings.

`&&` and `||` are short-circuit boolean operators. They elaborate through `op_and` and `op_or`, but the right operand is passed as a zero-argument function instead of being evaluated before the operation call.

`a && b` desugars to a call equivalent to `op_and(a, fn() { b })`. `a || b` follows the same rule with `op_or`. The resulting direct named call may use Contextual Resolution to supply the operation value.

Ordinary calls to `op_and` and `op_or` are strict. Only the `&&` and `||` operator syntaxes thunk the right operand.

Concrete expression precedence, associativity, and unary/binary disambiguation follow the MoonBit parser reference where Lane2 has not deliberately removed a feature.

= Core Language and ANF

Buslane is the Lane2 Core Language. It is a typed expression-tree language produced after source elaboration and before administrative normalization.

A Buslane program contains nominal type declarations, typed function declarations, typed value declarations, and typed expressions. It does not contain source-only syntax such as pipeline expressions, operator tokens, contextual offer lookup, omitted contextual arguments, field punning, or unresolved names. Buslane expressions preserve ordinary expression structure: calls, type applications, conditionals, matches, field access, nominal construction, function values, type lambdas, literals, and unsafe builtins are represented directly.

ANF is a later intermediate representation, not the Core Language. ANF preserves Buslane typing and evaluation behavior while introducing atom, right-hand-side, binding, and temporary structure to make evaluation order explicit. A conforming implementation may evaluate Buslane directly or may lower Buslane to ANF first, but the observable behavior of safe programs must be the same.

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
