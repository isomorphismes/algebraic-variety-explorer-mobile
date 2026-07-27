# Algebraic Variety Explorer

An offline Android explorer for real algebraic surfaces, adapted from
[IMAGINARY's SURFER](https://www.imaginary.org/program/surfer).

The app evaluates a polynomial in `x`, `y`, and `z`, then uses the original
jsurf ray-tracing core to draw its real zero set inside a sphere.

The Android adaptation and flat build were produced in conversation with
ChatGPT 5.6. They have not received an independent code or mathematical review.
This is experimental software, posted for people willing to test it rather than
represented as a finished or verified tool. Known defects and proposed work
belong in the
[GitHub issues](https://github.com/isomorphisms/algebraic-variety-explorer-mobile/issues);
an open issue is not silently being treated as finished functionality.

## Features

- Original polynomial parser and CPU ray tracer from jsurf
- Drag to rotate and pinch to zoom
- Sphere, torus, Cayley cubic, Whitney umbrella, Roman surface, and heart examples
- PNG export through Android's system file picker
- No internet permission, ads, analytics, account, or native libraries

Use `^` for powers and write multiplication explicitly with `*`. For example:

```text
(x^2+y^2+z^2+0.4)^2-1.1*(x^2+y^2)
```

## Build

There is no Gradle project and no generated directory hierarchy in the source
tree. The build is an explicit sequence of Android command-line operations:
resource compilation, Java compilation, conversion to DEX, APK assembly,
alignment, and optional signing.

Requirements:

- Bash, curl, zip, and unzip
- JDK 17
- Android SDK platform 35
- Android build tools

Set `ANDROID_SDK_ROOT` to the SDK directory, then run:

```sh
./build.sh
```

That produces a signed development APK under `.build`. The first build creates
a persistent local `.debug.keystore`; do not use that key for a published
release.

Other commands:

```sh
./build.sh release
./build.sh diagnostic
./build.sh test
./build.sh preview
./build.sh clean
```

`release` produces an aligned but unsigned APK for F-Droid or external signing.
`diagnostic` uses the separate package
`org.algebraicvarietyexplorer.local`, allowing it to install beside any
remaining copy of the real application. It is only an installation diagnostic
and must not be uploaded as the release.
The exact external Java dependencies and SHA-256 hashes are recorded in
`dependencies.lock`. They are downloaded into the ignored `.dependencies`
directory unless `ANTLR_JAR`, `VECMATH_JAR`, `JUNIT_JAR`, or `HAMCREST_JAR`
points to a supplied copy.

R8 keeps all project classes and members unchanged. Its only shrinking job is
to remove unreachable desktop-only classes from the old ANTLR and Vecmath
dependency jars before they reach Android.

## Read the source in this order

The Android adaptation is small. Start with these files:

1. `MainActivity.java` — the whole screen-level sequence: connect the views,
   configure input and buttons, request renders, and save PNG files.
2. `SurfaceRenderController.java` — runs one render at a time and returns the
   newest result to the screen.
3. `RendererEngine.java` — translates the app's formula, camera, material,
   lighting, and quality choices into calls to jsurf.
4. `AlgebraicSurfaceView.java` — displays the bitmap and turns drag/pinch
   gestures into rotation and zoom.
5. `RenderRequest.java`, `RenderResult.java`, and `RenderQuality.java` — the
   plain data passed through the rendering boundary.
6. `PngExporter.java` — writes a rendered bitmap.
7. `SurfaceExample.java` and `SurfaceExamples.java` — the example list.

The execution path is:

```text
MainActivity
    → SurfaceRenderController
        → RendererEngine
            → CPUAlgebraicSurfaceRenderer
```

Files whose package begins `de.mfo.jsurf` are the inherited 2008 ray tracer and
algebra library. They retain the original style because rewriting working
numerical code merely to make it look newer would make this first port harder
to verify.

`AlgebraicExpression.g` and `AlgebraicExpressionWalker.g` are the readable
grammar sources. `AlgebraicExpressionLexer.java`,
`AlgebraicExpressionParser.java`, and `AlgebraicExpressionWalker.java` are
checked-in ANTLR-generated output. They are required by the current standalone
build but are not the files to read or edit when changing the grammar.

## Flat source layout

All maintained files are at repository root. Java package declarations remain
unchanged; Java does not require source files to be stored in matching package
directories when they are passed to the compiler explicitly.

- `*.java` contains application and jsurf source.
- `*.test.java` contains JVM tests and the visual smoke test.
- `drawable.*.xml`, `layout.*.xml`, and `values.*.xml` are Android resources.
- `*.g` contains the original ANTLR grammar.
- `store.*.txt` contains F-Droid listing text.

Android's resource compiler requires `drawable`, `layout`, and `values`
directories. `build.sh` reconstructs those directories temporarily under
`.build` and leaves the repository flat.

The two original packages each had a file called `Helper.java`. The
package-private CPU renderer file is stored as `CpuHelper.java`; its contents
and class name are unchanged. The three generated ANTLR Java files remain
checked in and are compiled directly, so building does not require the ANTLR
generator.

## F-Droid submission

See `fdroid.README.md` and `org.algebraicvarietyexplorer.yml.template`.

## Attribution and license

The jsurf ray-tracing core was written by Christian Stussak for the
Mathematisches Forschungsinstitut Oberwolfach as part of IMAGINARY's SURFER.
The original core and this adaptation are distributed under the Apache License
2.0. See `LICENSE` and `NOTICE`.
