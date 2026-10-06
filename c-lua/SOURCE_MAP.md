# Java -> C -> C+Lua source map

Source of truth for semantics is the Java on branch `surfer`. The pre-existing
`native/surfer_raytracer.c` is valuable regression material, but it is not used
as a substitute for reading the Java source.

| Java / grammar source | New owner | Status |
| --- | --- | --- |
| `UnivariatePolynomial.java` | `c-lua/surfer_poly.[ch]` | direct C slice: construction, arithmetic, power, evaluation, derivative, shifts, Descartes sign helpers |
| `RealRootFinder.java` | `c-lua/surfer_poly.h` | C API shape represented |
| `ClosedFormRootFinder.java` | `c-lua/surfer_poly.c` | direct C translation for degrees 0-4 |
| `AlgebraicExpression.g` | `c-lua/idric/AlgebraicExpression.idric` | typed recursive-descent grammar after tokenization |
| `AlgebraicExpressionWalker.g` | Idric AST/lowering boundary | AST shape carried; C-lowering validation still to implement |
| `RendererEngine.java` | `c-lua/lua/surfer.lua` + C renderer | camera/material/light/quality/formula policy moved to Lua; numerical renderer remains C |
| `SurfaceExamples.java` | `c-lua/lua/surfer.lua` | translated to Lua data |
| `CPUAlgebraicSurfaceRenderer.java`, `RenderingTask.java` | inherited `native/surfer_raytracer.c`, then direct-C completion | substantial C ray path already exists; exact Java specialization/AA/concurrency parity remains |

## Why the split is two-stage for the numerical core

The root finder and polynomial transformations are numerically sensitive and
already have a Java oracle obligation in issue #17. They stay direct Java -> C
until parity is measurable. Lua receives state/configuration/orchestration now,
because moving those concepts does not obscure floating-point differences.

Once the C parity surface is stable, additional non-hot control logic can move
from C into Lua without changing the numerical ABI.
