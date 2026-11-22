# Original transformed polynomial specialization

The existing explicit-quality C renderer specializes each sparse term directly
along a ray and evaluates sparse derivatives at the hit. The original renderer
instead transforms four XYZ polynomials once, applies `evaluateZ(v)` for a row,
then `evaluateY(u)` for a pixel and evaluates the three resulting gradient
univariates at the root. These paths have different floating-point operation
orders. A matching algebraic expression is insufficient evidence of equivalence.

The implementation cut keeps formula parsing and symbolic differentiation in
Idriç. C receives the same immutable prepared polynomial arrays. Private owned
XYZ/XY/dense-univariate values preserve the original sorted-product Kahan
collection, nested substitution and forward/inverse Horner evaluation. A render
owns four transformed XYZ values and a bounded cache of immutable row values;
each sample owns its univariate coefficients. Every private allocation uses the
existing caller-owned status/fault/cancellation context. Failure invalidates the
new frame, and the outer frame/session owner retains the preceding display.

The legacy single-sample API remains a historical byte-comparison control.
The explicit quality and cancellable session entries select the transformed
pipeline. No approximate path is selected by the new Activity.

The independent test adapter invokes unchanged Java classes frozen at
`cfd543e1886bc6b7eb9e1ede6641569b673aac8d`. It records exact input coordinate
polynomials, transformed terms, row terms, dense coefficients and gradient
values. The C test reads those observations; it does not reproduce the Java
algorithm as a second oracle. Preset, cancellation, reciprocal and Kahan cases
must exercise both Horner directions and nontrivial rotations/coordinates.

Original camera normalization, complete lighting/image equivalence and the
host-dependent overlapping tile partition remain distinct obligations. This
slice initially compares the same explicit coordinate polynomials. No camera,
APK or physical-device acceptance follows from specialization observations.

## Reduced discrepancy and observations

The preserved `direct-discrepancy.c` uses the old direct expansion on a sphere
with the explicit rotated map at u=v=-1. Its linear coefficient is positive
zero, while the actual original nested method returns binary64 bits
`bc90000000000000`. Constant and quadratic coefficients agree. This is a real
operation-order discrepancy, not an assumed effect of algebraic equivalence.

With the recovered exact ICK compiler, all 30 same-map cases, 120 transformed
polynomials, 840 rows/columns and 5880 univariate/gradient evaluations match
the original method bytes. The retained local reference was the explicitly
recorded Java21/source17 exploratory profile; the maintained reference runner
requires frozen original sources and Java17 and remains a hosted gate.

Both render modes pass every observed transformed cubic allocation fault
(228 Interactive, 317 Final) and 33 cancellation checkpoints each. Four real
compiled changes are rejected by the unchanged original-byte observer: removed
Kahan correction, wrong row direction, wrong column direction and a wrong
substitution exponent. Existing core/status, AA, frame and session tests pass;
15 F32 blends, 682 bounded pixels and all 32179 legacy successful bytes remain
unchanged (SHA256 `65f44c201676e330068804e4059a369cb6479efa1673660fd78a42681a1f55ca`).

The maintained candidate helper executes ordinary comparisons, faults, mutants
and legacy-byte checks locally, then correctly stops at mandatory leak checking:
LeakSanitizer cannot run under this environment's ptrace. The same ASan/UBSan
binary passes with local leak detection explicitly disabled. Hosted Java17,
leaks, ABI/JNI, full original camera/lighting/tile and physical-device evidence
remain pending. No alternate compiler or candidate Java was introduced.

## Finite arithmetic boundary

The native finite-intermediate validation contract remains for used results.
The original power routine also performs an unused final square. A generic map
coefficient such as 1e80 raised to three has a finite used result but its unused
square overflows. The native routine now skips that dead square instead of
rejecting the finite result. Six independent original observations cover
positive and negative constants raised to three, five and seven. Every used
multiply retains its original order; discarded allocations are not part of
the surface value. Complete finite-domain, camera and image acceptance still
remains required.

The six added actual original power observations pass locally with the exact
qualified ICK compiler and the explicitly labelled Java21/source17 reference.
After eliminating dead squares, the same fault sweep observes 216 Interactive
and 305 Final allocation points; every one still returns out-of-memory on its
designated fault. These replace the earlier counts for this revision. The
maintained gate additionally compiles a mutation restoring the dead square and
requires rejection by the finite original power observations. Hosted JDK17 and
leak acceptance must be rerun for this changed source.
