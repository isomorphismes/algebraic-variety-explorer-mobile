# Located formula admission

## Type sketch before implementation

The production lexer and parser will preserve the existing token kinds,
expression constructors, grammar, precedence, accepted numeric lexemes and
legacy error text. Source positions count `Text` characters after `unpack`,
starting at zero; spans are half-open and EOF is the empty span at source length.
Whitespace consumes positions without producing tokens. This is character
position evidence, not a UTF-8 byte offset or an Android UTF-16 selection index.

`SourceSpan` holds start/end natural character offsets. `SpannedToken` holds a
real existing token and its source span. `ParseError` holds a closed typed
lexical/parser category and a source span. Missing expected input points to the
next offending character/token or the EOF empty span. A malformed leading-zero
decimal identifies its complete literal.

The central operations are pure:

- `lex_formula_spanned : Text → Either ParseError (List SpannedToken)`
- `parse_formula_detailed : Text → Either ParseError Expression`
- `parse_error_message : ParseError → Text` preserves legacy error messages.
- `parse_error_report : ParseError → Text` adds exact character bounds.

The existing `lex_formula` and `parse_formula` are projections of this one
production implementation. Semantic qualification carries the actual typed
syntax error rather than flattening it early. Existing semantic reports keep
their legacy wording; the real Activity uses the located preparation wrapper
so its rendered error includes the source bounds. No parallel demonstration
parser, formula-language change, arithmetic change or new platform UI is added.

The generated Idriç host checks exercise accepted token spans, precise
lexical/parser failure categories and bounds, legacy text, unchanged expression
shape and typed semantic qualification. Managed exports compile those same
source paths and actual located preparation through the existing checked DEX
writer and independent decoder. Host/source emission and ART observations
remain separate. The expression constructors remain the established semantic
AST; this slice adds token locations and syntax-error locations, not source
locations for every semantic AST node or later meaning/evaluation error.

## Attempt and result

The single production lexer now emits `SpannedToken`. The production precedence
parser consumes that stream and returns `ParseError` on failure. `lex_formula`
and `parse_formula` project away location/error metadata while preserving their
established public result types and messages. `qualify_formula` retains the
typed error in `FormulaSyntaxFailure`. Preparation uses a shared formatter
parameter; the compatibility wrapper preserves old messages and the actual
Activity's `prepare_request` calls `prepare_formula_located`.

The first host attempt needed an explicit CoefficientValue import for the
exposed coefficient type. After that correction, compiling actual preparation
for the host reached the existing concrete boundary: CoefficientValue's
`dex:static:Ljava/lang/Math;:tan:(D)D` declaration has no Chez backend mapping.
The failed combined sources are retained under `attempts/host-platform-math/`.
No alternate arithmetic implementation was introduced. Host checks cover the
available parser and typed semantic admission; the actual preparation is
compiled for its requested DEX backend and has an independent ART observer.

The exact frontend is740bbf2b1d9e811fd00c719c3473eede17ceea3b, Chez compiler
SHA2567aebab74161e120a7ffb18ab500468a505a9ae1c32fb5aa3557959c2b584cc97.
The existing checked driver used here has
SHA256a2641ca7eb34f596b6d3ad9a9ba821b7014d5116ec1454572e6ab80f9f45b773.
All orchestration parses and executes through the recovered pinned Grease
runtime. The qualifier records the exact source snapshots and input hashes.

The host corpus passes28 checks: three exact token streams,20 rejection
categories/ranges, accepted power precedence, two legacy reports, typed semantic
failure transport and the actual syntax formatter. Existing FormulaCheck and
PolynomialQualificationCheck pass unchanged. Two compiled source mutations are
rejected: shifting real numeric/name token starts and replacing the scientific
exponent error category. These are host observations, not ART mutation results.

The source-owned token, detailed syntax and actual located preparation exports
compile through the managed writer, independently decode and reassemble. The
normal20-module Activity with the new preparation call also compiles and
independently decodes/reassembles; its original emitted candidate SHA256 is
55d333acd0e0413923003cd0b33e92633eeb232c8bc90f25a38c1e05a4b89d00.
Use original emitted bytes, not the reassembly, as the candidate.

The independent SpannedFormulaRunner has11 fixed observations of actual emitted
exports, including exact tokens, EOF, scientific digits, astral Unicode,
parentheses, source range formatting, successful semantic preparation and the
unchanged divisor restriction. It assembles/decodes locally, SHA256
7ac37a54feec2246b70451fe4ccc961eb72396a0629480f8a675608bbf7be25c.
`observe.grease` requires the exact API34 x86_64 emulator, transfers and compares
the candidate/observer bytes, bounds execution and accepts only the exact PASS
marker with exit0. ART execution, installed Activity error display and physical
devices remain NOT_RUN until their actual qualification succeeds.

The first exposed language/backend boundary is the existing absence of a Chez
mapping for the DEX-only platform coefficient functions. This task does not
need a fallback. A future generic host mapping would need to execute the same
prepared-formula corpus with independently checked binary64 results; parser
metadata alone would not qualify that arithmetic boundary.
