# Java → D source map

Source of truth: the Java files on the `surfer` branch.

The D port is intentionally source-led. The older `d/desktop-surfer` branch is
useful comparison material, but it is not a substitute for translating a Java
source file here.

| Java source | D source | Status | Notes |
| --- | --- | --- | --- |
| `UnivariatePolynomial.java` | `source/de/mfo/jsurf/algebra/univariate_polynomial.d` | translated | Class and methods retained; D arrays replace Java arrays. |
| `RealRootFinder.java` | `source/de/mfo/jsurf/algebra/real_root_finder.d` | translated | Interface retained. |
| `ClosedFormRootFinder.java` | `source/de/mfo/jsurf/algebra/closed_form_root_finder.d` | translated | Closed-form algorithms retained. |
| `DescartesRootFinder.java` | `source/de/mfo/jsurf/algebra/descartes_root_finder.d` | translated | Active root-isolation path retained; Java benchmark `main` is not part of the library module. |

## Porting rules

1. Read the Java file first.
2. Add the corresponding D module without routing through the C or earlier D
   implementation.
3. Keep algorithmic oddities until an independently reviewed cleanup changes
   them.
4. Preserve Apache-2.0 attribution headers on translated inherited source.
5. Mark a file translated only when its source has actually been carried over;
   a stub, plan, or analogous implementation is not translation completion.

## Explicit D adaptations so far

- Java array copies use D slices/`dup` while retaining copy-versus-alias intent.
- Java varargs coefficient arrays are explicitly duplicated on entry because D variadic slices may be temporary; this preserves the Java object's retained-array lifetime.
- `Double.longBitsToDouble`/`doubleToLongBits` in `DescartesRootFinder.nextPowerOfTwo` use a D union to reinterpret the same IEEE-754 binary64 bits.
- The executable benchmark loop embedded as `DescartesRootFinder.main` is omitted from the library module; it is not renderer semantics.
