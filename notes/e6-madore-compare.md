# David A. Madore's cubic `E₆` in SURFER

**Original mathematician and animator: David A. Madore.**  
**Original film:** [`03s01a` in *The Cubic Surfaces DVD*](http://www.madore.org/cubic-dvd/) (2006).  
**Source copied and credited in:** [`isomorphisms/resolution/vendor/david-madore/cubic-dvd/`](https://github.com/isomorphisms/resolution/tree/main/vendor/david-madore/cubic-dvd).  
**Original scene:** [`03s01a.pov`](https://github.com/isomorphisms/resolution/blob/main/vendor/david-madore/cubic-dvd/upstream/cubic-dvd/03s01a.pov).  
**This rendering core:** Christian Stussak's `jsurf` for IMAGINARY/SURFER, Apache License 2.0, see [`NOTICE`](../NOTICE).

## Mathematical object

Madore's first `E₆` POV-Ray scene uses cubic coefficients `A4=A8=A11=1` (POV-Ray's documented cubic monomial order). These give the **exact** polynomial

```text
x^2 + x*z^2 + y^3
```

The origin is a singular point. Completing the square,

```text
(x + z^2/2)^2 + y^3 - z^4/4 = 0
```

displays a complex-analytic `E₆` rational double point after a holomorphic rescaling. It is *not* a movie of the resolution. The renderer displays the **real zero set in R³**, not the full complex surface.

## Two engines, one underlying equation

| Engine | What is rendered | Camera / cut-off | Output |
|---|---|---|---|
| **SURFER / jsurf** | Actual zero set `F=0`, original CPU ray tracer by Christian Stussak | Orthographic, height `2.15`, unit-sphere clipping, fixed pitch, full yaw turn | [`madore-e6-surfer.mp4`](../renders/madore-e6/madore-e6-surfer.mp4) and [GIF](../renders/madore-e6/madore-e6-surfer.gif) (when generated) |
| **Madore's POV-Ray** | Thin `-10^-4 ≤ F ≤ 10^-4` volume clipped inside a radius-4 sphere, using his unmodified `03s01a.pov` | Perspective at `(0,5,-20)`, rotating object, fixed RGB lights | [POV-Ray film in `resolution`](https://github.com/isomorphisms/resolution/tree/main/renders/madore-e6) |

These videos deliberately are **not framewise image-equal**. They use different projection, clipping radius, lights, shading and surface thickness. They should display the same polynomial zero set up to the POV-Ray tolerance and clipping conventions.

## Reproduce this SURFER movie

On a machine with JDK 17, Python 3, `ffmpeg`, `ffprobe`, Bash and internet access to the exact dependencies pinned in `dependencies.lock`:

```sh
bash tools/render-madore-e6.sh renders/madore-e6
```

Defaults: 32 frames at 320×320, 16 fps, full yaw turn, fixed pitch `−0.35` radians. This compiles and tests the actual Java `de.mfo.jsurf` core, renders real PPM frames with `JsurfPreview`, encodes MP4 and GitHub-friendly GIF, saves a PNG still and a JSON manifest, then verifies decoded frame colors, a bounded foreground, frame changes, and the encoded MP4 frame count.

The unmodified default preview parameters stay `yaw=0.55`, `pitch=−0.35`, `size=256`; the original sphere preview byte checksum remains a regression gate.

The `Madore E6 cubic` preset in the Android app takes exactly this formula. A successful desktop JVM render does **not** establish that this animation is working inside Android; the Android app currently accepts interactive drag rotations and PNG export rather than importing pre-rendered MP4 files.

## Acknowledgments and reuse

**Thank you to David A. Madore** for the mathematics, the animations and the entire original public-domain POV-Ray source; he specifically requests that his authorship be acknowledged. This rendering is an **independent SURFER/jsurf rendering of his cubic**, not a claim that Madore created this app or its Java renderer.

**Thank you to Christian Stussak and IMAGINARY at the Mathematisches Forschungsinstitut Oberwolfach** for SURFER and its Apache-2.0 `jsurf` CPU ray tracer. The original POV-Ray material is public domain under Madore's terms, while the distinct jsurf renderer remains Apache-2.0. Do not confuse their authorship or their licenses.

Any subsequent comparison with `A₁`, `D₄`, `E₈` blowup movies should record the map `Y→X`, the exceptional divisor and the plotted real slice: deformation and resolution are different operations.
