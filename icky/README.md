# SURFER in Icky D

This directory is the beginning of the whole-program SURFER translation to Icky D.

The endpoint is not a second isolated ray tracer. The completed translation must replace the reachable Java/jsurf application path with Icky D plus explicit Android/operating-system boundaries, while preserving the observable parser → algebra → ray → root → gradient/normal → pixel behavior recorded by the existing SURFER oracle work.

## First executable vertical slice

The first slice deliberately crosses several existing preservation boundaries together:

1. parse a polynomial formula with explicit multiplication, parentheses, ASCII powers, and the already-requested single-character superscripts `²` and `³`;
2. build a sparse polynomial and its three symbolic derivatives;
3. specialize that prepared surface along a ray;
4. preserve the shared ray parameter through unit-sphere clipping and surface root selection;
5. evaluate the gradient at the selected surface-space hit and transform the normal back to camera space;
6. shade the hit and render the current orthographic yaw/pitch camera slice.

Geometry, polynomial coefficients, root work, and transforms remain binary64 in this parity slice. Material and color work remains binary32. Issue #9 can compare narrower representations against this behavioral reference instead of silently changing the translation while it is still being recovered.

The root implementation is independent rather than a line-by-line port of the Java or C implementation. It isolates real roots through derivative critical points and bisection, including even-multiplicity roots. Issue #17 remains the authority: this algorithm is acceptable only insofar as the Java oracle corpus proves the same required behavior.

## Compiler boundary

This source intentionally uses the Icky D surface accepted by the repository's Mars/DMD line, including mathematical minus, equality/inequality glyphs, and multiplication glyphs. CI builds the exact qualified Icky DMD commit before compiling this code; stock D is not the acceptance compiler for this directory.

The slice is BetterC so the numerical/parser nucleus does not acquire a hidden druntime or Phobos dependency while the Android boundary is still being translated.

## Still in scope

This branch is not complete until the whole reachable application path has moved across:

- the complete SURFER formula grammar and error behavior;
- exact polynomial collection/specialization order and oracle parity;
- production root edge cases from issue #17;
- full ray/transform/zero-gradient behavior from issue #20;
- adaptive antialiasing and production quality modes;
- renderer request concurrency, cancellation, and latest-request-wins;
- materials/lights and all current examples;
- Android gestures, controls, PNG export, lifecycle, and packaging without Java;
- differential image/intermediate-value oracle coverage;
- physical-device acceptance.

The existing Java and C code stay as oracle/reference material during the translation. This branch does not claim they can be removed yet.
