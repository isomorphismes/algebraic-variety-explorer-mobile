# SURFER in Icky D

This directory contains the first executable SURFER numerical and formula path
translated to Icky D. It now parses and renders the six shipped surface
examples, but it does not yet replace the Android application.

The endpoint is not a second isolated ray tracer. The completed translation must replace the reachable Java/jsurf application path with Icky D plus explicit Android/operating-system boundaries, while preserving the observable parser → algebra → ray → root → gradient/normal → pixel behavior recorded by the existing SURFER oracle work.

## Translated and exercised

The translated path currently covers:

- the polynomial-compatible part of SURFER's formula grammar: `x`, `y`, and
  `z`; `+`, `−`, `*` and `×`, scalar `/`, unary signs, parentheses, ASCII
  integer powers and `²`/`³`; decimal and exponent-form constants; and the
  source language's unary mathematical functions when their argument is a
  constant;
- sparse polynomial collection, symbolic x/y/z derivatives, and ray
  specialization;
- unit-sphere clipping and surface-root selection on the shared ray parameter;
- gradient evaluation and camera-space normal transformation;
- the app's interactive one-sample renderer and final adaptive QUINCUNX
  supersampling renderer, with its current yaw/pitch view, front/back
  materials, background, and three lights;
- the Sphere, Torus, Cayley cubic, Whitney umbrella, Roman surface, and Heart
  formulas, including their expected total degrees and deterministic repeated
  pixel output;
- 256×256 single-sample differential renders of all six examples against the
  original Java/jsurf renderer, using yaw `0.55`, pitch `−0.35`, and the app's
  materials, lights, and background;
- the same six image comparisons in the app's adaptive QUINCUNX mode.

The formula tests also reject non-polynomial operations such as division by a
coordinate, nonconstant function arguments, unsupported variables, and
compound powers. These follow the original parser/walker boundary rather than
silently treating those inputs as polynomials.

Geometry, polynomial coefficients, roots, and transforms remain binary64;
materials and colors remain binary32. The renderer is compiled and run as
ordinary D with the matching Icky DMD, druntime, and Phobos revisions. BetterC
is no longer the acceptance boundary.

The current root routine isolates roots through derivative critical points and
bisection, including even-multiplicity roots. Its Java/jsurf oracle fixtures
cover a tangent root, a repeated cubic root, a near-double pair, a narrow
interval with no source root, and four ordered quartic roots. Tightening the
critical-value tolerance fixed a near-double false positive found by that
comparison. The translated routine is not yet the source Descartes
implementation, and the full adversarial corpus in issue #17 remains
outstanding. Across the twelve 256×256 comparisons, eight images have zero
changed pixels. The largest difference is the Roman surface in QUINCUNX mode:
normalized mean absolute channel error `0.000116`, with `0.38%` of pixels
changed. The test requires mean error at most `0.0002` and at most `0.5%`
changed pixels; a half-black known-bad fixture proves that the comparison
rejects a broken render.

## Remaining program

This translation does not yet include:

- the source Descartes subdivision implementation and the broader adversarial
  corpus required by issue #17. The app's constant/linear path is translated;
  the unused degree-2-to-4 generic closed-form solver is not ported;
- renderer request concurrency, cancellation, and latest-request-wins behavior.
  The translated renderer currently runs synchronously;
- the Android screen, gesture controls, PNG export, lifecycle, and a Java-free
  app package. Icky DMD rejects both Android target triples before object
  generation; [the compiler blocker and minimal reproducer](android-target-blocker.md)
  record the exact boundary;
- physical-device execution. No translated APK exists to install or run.

The source tree's original Java and C renderers remain the references. The
repository's original Java test command passes, and the separate D suite runs
with Icky DMD plus the pinned matching runtime and Phobos. The Java image
oracle and Icky D comparison run for every shipped example in the pull-request
workflow. These host renders do not claim physical-device evidence.

The draft stays incomplete until those remaining program pieces and acceptance
checks have been translated or each omitted boundary has a specific, reviewed
reason.
