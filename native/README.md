# SURFER native ray tracer

This directory resumes the numerical ray-tracer translation at the corrected
`PreparedSurface` boundary. It does not replace the Java renderer yet.

Christian Stussak's original jsurf/SURFER renderer remains the oracle. The
numerical path here intentionally preserves the original split between F64
geometry/polynomial/root work and F32 material/color work.

## Implemented slice

`surfer_raytracer.c` currently owns a complete single-threaded prepared-surface
ray path:

1. receive one surface polynomial and its three prepared derivatives as sparse
   F64 terms;
2. specialize the surface to a dense polynomial along a ray;
3. clip the ray to the unit sphere while preserving its original parameter;
4. choose the first visible root, using the linear closed-form path for a
   degree-below-two family and a direct port of SURFER's Descartes subdivision
   path otherwise (`EPSILON = 1e-7`, no square-free conversion);
5. evaluate the prepared gradient at the hit;
6. transform and normalize the normal, choose front/back material, and apply
   SURF-style ambient/diffuse/specular lighting;
7. convert F32 color to Java-compatible ARGB rounding;
8. render the current orthographic yaw/pitch/zoom camera slice.

The ray bundle keeps camera, clipping, and surface rays distinct. That is not
ceremony: SURFER uses the same ray parameter in three coordinate spaces, shades
at the camera-space hit, and solves the polynomial in surface space.

## Host acceptance

From the repository root:

```text
make -f native/Makefile test ICK_CC=/absolute/path/to/qualified/ick
```

The maintained C nucleus uses `÷` and is compiled directly by ICK revision
`c61e448251744a2f40ad743ebef1a027bdcd2f9d`. CI provisions that exact compiler
through the shared `ick-host` action and runs the original AddressSanitizer and
UndefinedBehaviorSanitizer profile with leak detection. `SANITIZE=1` selects
that profile locally. This host-only producer does not add native libraries to
the Java APK or change its existing native-payload rejection policy.

The source-inventory guard checks all maintained native C/header code for
14 executable `÷` operators and no ASCII quotient operators. It must reject
deliberate regressions to `/`, `/=`, or a missing operator; comments and
string literals do not count. The native test runner also executes a separate
negative-control process: an approximate comparison against `NaN` must exit
with status 1 and its expected failure marker, not merely produce an ordinary
green test result.

The tests cover ray-parameter-preserving sphere clipping, first-root selection,
an exact even-multiplicity tangent root, a miss, the low-degree linear path,
normal orientation, a rendered sphere with foreground/background, and a rotated
sphere silhouette.

## Not parity yet

This is the restored ray-tracing nucleus, not a claim that Java can be removed.
The remaining numerical translation includes:

- exact `XYZ -> XY -> univariate` specialization/evaluation order and Kahan
  collection parity rather than the current direct sparse-to-ray expansion;
- gradient specialization parity rather than direct sparse derivative
  evaluation at the hit;
- adaptive antialiasing and the production `OG_1x1` / `QUINCUNX` behavior;
- renderer worker concurrency, cancellation, and latest-request-wins behavior;
- the versioned `PreparedSurface` primitive-array/JNI ownership boundary;
- the frozen Java semantic/numerical/image oracle corpus required by issue #17.

The old pure-Idris ray tracer remains historical reference work. The maintained
replacement architecture is the typed Idriç semantic front end followed by this
C numerical layer and a thin Android shell.
