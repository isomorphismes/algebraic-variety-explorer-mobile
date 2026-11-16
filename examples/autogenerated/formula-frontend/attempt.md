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

After provisioning `rg`, source `91c0317f94604faf197f0facaf188431117bbeea`
passed the host checks again in
[run 43785426435](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43785426435).
Direct DEX production then stopped before lowering with `Undefined name main`.
The grammar is a library, so its pure export now has a separate
`FormulaExports.idric` adapter with the same no-op source entry used by the
canonical managed-export fixtures. Both original and mutated parser graphs are
compiled through that adapter; no substitute grammar is introduced.

At `ae30e678f178045949fa7721d978b8fac5a98237`,
[run 43786388990](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43786388990)
generated and independently decoded the parser DEX, reproduced identical bytes,
executed the unchanged observation runner on API34 ART, and rejected the actual
compiled parser mutation with its designated status73. The whole run still
failed: the coefficient driver had no `%export` entry selected and therefore
never tested numerical lowering. The entry is now declared explicitly.

The next source stage is `PolynomialQualification.idric`. Its working source
passed the host checks with the exact retained frontend740bbf2b1 and emitted
a 159424-byte DEX containing both public Text exports through backend153e7fc.
Pinned baksmali decoded it independently; the combined observation runner also
assembled. These are local host/generation/decode observations, not ART or APK
acceptance of the new stage. The candidate SHA256 was
`d271d41db8bcd0a81db1d691258c657ef13665a8c05199698b7d062a9b57428f`.
The required hosted continuation executes both semantic layers and rejects a
second compiled mutation that bypasses the polynomial-divisor restriction.

The corrected coefficient driver, executed against the retained current backend,
now reports the first checked runtime refusal: `Managed DEX unsupported text
cast from Double` in `Prelude.Show`. That is the output-formatting path of this
probe; it is not evidence that the application's numerical C owner must move.
Arithmetic and original-jsurf literal parsing must be qualified separately.

## First language boundary

The next qualification must compile the real parser rather than a backend-owned
substitute. A separate F64 coefficient program checks whether the numerical
primitives required by the actual polynomial producer are implemented. Preserve
its exact compiler diagnostic before assigning any remaining compiler work.

## Actual scalar producer execution

Application source `d4bc9b3c84d8adeb4c82d1354c84833aace5aec9` completed
run43792136217 successfully through backend73dc476. The real parser,
scalar/polynomial qualifier and app-owned coefficient evaluator all executed on
API34 ART. The coefficient observer checked exact value bits against both
independent constants and the retained original jsurf evaluator. The parser,
divisor-rule and coefficient-sum compiled mutations failed their designated
assertions. The old generic Show/cast experiment is retained as history;
the actual producer does not use those broader operations. New semantic
preparation/expansion and managed/native transfer remain separate stages.
