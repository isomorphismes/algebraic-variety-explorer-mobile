# Explorer formula front end

## Purpose and source

Continue the retained `C+Lua` parser at `00b05c143580c5d691f3a10987d4c31623b706a3`,
`c-lua/idric/AlgebraicExpression.idric`. That checkpoint accepted already-made
tokens; it had no lexer, executable tests or polynomial lowering. The source
grammar is Christian Stussak's `AlgebraicExpression.g` and its tree walker,
preserved at repository root with the Apache-2.0 notice.

The application outcome remains an Idriç semantic front end, the maintained
F64 C numerical renderer, and an Android framework interface generated directly
as DEX. This change is the actual source-text parser required by that path. It
does not turn the native C bootstrap parser into the intended semantic owner.

## Type sketch

- `Token` distinguishes decimal integer text from floating text, names and
  punctuation. Numeric lexemes are retained exactly; parsing does not round
  them to Float16 or silently change F64 semantics.
- `Expression` describes constants, names, arithmetic and single-argument calls.
  `Grouped` retains explicit parentheses.
- `lex_formula : Text → Either Text (List Token)` rejects unknown characters,
  malformed scientific notation and malformed literals.
- `parse_formula : Text → Either Text Expression` consumes the entire source.
- `expression_shape : Expression → Text` is a structural observation boundary,
  not the renderer's permanent representation or a numerical evaluator.
- Recursive descent has an explicit source-derived budget. Every recursive
  descent consumes budget, so malformed/cyclic parser control cannot hang.
- The parser is pure. Console/ART qualification belongs in the example driver.

Required facilities are Text/Char traversal, lists, records, algebraic cases,
ordinary non-tail recursion and pure Text exports. These should use the current
managed DEX runtime; no Java, RefC or alternate parser is a fallback.

## Semantic boundaries

Preserve the original grammar: explicit multiplication, right-associative power,
negation outside power, one optional unary minus, ASCII identifier vocabulary,
decimal/scientific literals and unary constant-function syntax. `=0` is an
application convention, not part of the original expression grammar. Polynomial
qualification (constant denominators, decimal-only polynomial exponents),
numeric evaluation and differentiation remain the next semantic stage.

## Execution

At `cf73012460ed9b101d7599523ab11e6e676a5c60`,
[run 43609098012](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43609098012)
built the pinned frontend and DEX driver, compiled `FormulaCheck.idric`, and
executed all nine positive host checks and the malformed-input refusals. The
whole run failed because `rg` was absent from the runner. That infrastructure
failure occurred before direct DEX emission. The retained artifact is
`14120676609`; its downloaded archive identity recorded by Actions is
`891833740335989dcef5ecaaf1107368a865f98589fb1c5d2a8c23b5661a13d4`.

The workflow now provisions the declared dependency. Diagnostic scanning also
distinguishes a clean log (status 1) from a broken checker (status >1), so a
missing checker or unreadable log cannot certify clean compiler output.

PENDING: direct DEX emission, independent decoding and ART execution. No APK,
JNI polynomial handoff, renderer equivalence or physical-device result is
claimed by the host result.

## First language boundary

The next qualification must compile the real parser rather than a backend-owned
substitute. A separate F64 coefficient program checks whether the numerical
primitives required by the actual polynomial producer are implemented. Preserve
its exact compiler diagnostic before assigning any remaining compiler work.
