# SURFER in D — desktop baseline

This directory is an independent D recasting of Christian Stussak's original
`jsurf`/SURFER CPU renderer. It starts from the Java renderer's semantics rather
than from the later Android, JNI, C, shader, Float16, or Idriç experiments in
this repository.

The comparison is intentionally desktop-first. There is no Android API, NDK
boundary, DEX code, JNI adapter, APK packaging, or mobile lifecycle here.

## Preserved rendering conception

The live Java CPU path is kept as the semantic reference:

- parse an algebraic formula in `x`, `y`, and `z` with scalar parameters;
- construct and collect a multivariate polynomial;
- differentiate it symbolically for the three gradient components;
- construct camera, clipping-space, and surface-space rays;
- substitute the surface ray into the polynomial;
- isolate the first visible real root with Stussak's Descartes strategy;
- clip against the unit sphere;
- evaluate the gradient and transform the normal back to camera space;
- apply the original front/back ambient + diffuse + specular shading model;
- use the original ordered-grid, rotated-grid, or quincunx sampling ideas;
- render pixels in parallel on the CPU;
- emit a plain PPM image so the renderer itself has no GUI or mobile dependency.

The mathematics remains binary64. This is not the later low-precision
experiment.

The D structure is deliberately not class-for-class Java. In particular,
`Polynomial` is a value with collected terms, vector/matrix objects are small
value types, and the renderer works directly with differentiated polynomials
rather than reproducing the Java visitor hierarchy and row-substitutor class
hierarchy.

## Build

With LDC or another current D compiler plus Dub:

```sh
cd d
dub test
dub build --build=release
```

Render the same sphere used by the Java preview:

```sh
./surfer-d --output sphere.ppm \
  --formula 'x^2+y^2+z^2-0.64' \
  --width 512 --height 512 \
  --yaw 0.55 --pitch -0.35 --aa quincunx
```

Other formulas carried by the Java mobile adaptation remain useful comparison
fixtures:

```text
Sphere           x^2+y^2+z^2-0.64
Torus            (x^2+y^2+z^2+0.36)^2-1.69*(x^2+y^2)
Cayley cubic     x^2+y^2+z^2+2*x*y*z-1
Whitney umbrella x^2-y^2*z
Roman surface    x^2*y^2+y^2*z^2+z^2*x^2-x*y*z
Heart            (x^2+2.25*y^2+z^2-1)^3-x^2*z^3-0.1125*y^2*z^3
```

## Deliberate boundary

This branch answers one question first: *what does SURFER look like when it is
written as a D desktop program?* Android comes later, after this program is
understood on its own terms.
