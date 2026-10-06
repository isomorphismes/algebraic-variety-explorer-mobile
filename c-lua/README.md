# C + Lua SURFER translation

This branch is the Java -> C -> C+Lua experiment for Algebraic Variety Explorer.
It starts from the current `surfer` branch so it inherits the already-working
prepared-surface C ray-tracer nucleus under `native/`.

The new rule is stricter than the older compact native recast and the D branch:

1. Java and the two ANTLR grammar files are the semantic source of truth.
2. Numerically sensitive algebra/root/render code is translated to C first and
   kept recognizable until oracle parity is established.
3. Larger control concepts are then moved into Lua when doing so makes the C
   surface smaller without changing floating-point semantics.
4. The ANTLR grammar/tree-walker boundary is represented in Idric rather than
   carrying generated ANTLR Java into the eventual native program.

## What is implemented in this first cut

- `surfer_poly.c/.h`: direct C translation slice of
  `UnivariatePolynomial.java`, `RealRootFinder.java`, and
  `ClosedFormRootFinder.java`.
- `surfer_poly_test.c`: host tests for Java's two Horner directions, the special
  linear-power/binomial path, shift/reverse-shift behavior, quadratic/cubic/
  quartic roots, and repeated roots.
- `lua/surfer.lua`: `RendererEngine` policy plus the current surface catalog as
  Lua data/functions. Root solving, polynomial arithmetic, ray construction,
  intersection, and shading are intentionally not Lua.
- `idric/AlgebraicExpression.idric`: typed recursive-descent replacement shape
  for the ANTLR expression grammar after tokenization, preserving right-
  associative power and the old AST distinctions.
- `SOURCE_MAP.md`: traceability and explicit unfinished boundaries.

Host-test the new C slice:

```sh
cd c-lua
make test
```

The current host result is:

```text
SURFER Java->C polynomial/root slice: PASS
```

## Not claimed yet

This is not yet a whole-program native replacement. In particular:

- the Idric lexer and AST -> C polynomial lowering are not wired into the C ABI;
- `XYZPolynomial`/`XYPolynomial` and the full visitor/expansion/substitution
  family are not yet direct-C ports;
- the existing native renderer still needs exact Java specialization order,
  gradient specialization, antialiasing, concurrency/cancellation, and oracle
  comparison work called out by issue #17;
- there is no Lua/C binding or Android NativeActivity shell on this branch yet.

The branch is structured so those are implementation steps rather than another
architecture reset.
