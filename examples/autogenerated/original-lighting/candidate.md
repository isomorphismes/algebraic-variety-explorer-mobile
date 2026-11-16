# C lighting and bounded full-canvas qualification

The explicit-quality and cancellable numerical entries preserve the frozen
original collector and shader. Diffuse/specular products and color addition
remain binary32. The specular dot product and `pow` remain binary64 until the
original final cast to binary32. The back ambient product deliberately uses
the front ambient intensity, matching the original collector. Normal length
is cast to binary32 before its reciprocal; a zero dot product chooses the
back material. The historical direct-expansion single-sample entry retains its
earlier behavior as an unchanged successful-byte control.

The 44-frame corpus exposed a real root-selection defect: the C Descartes
entry checked the degree after trimming zero coefficients. The original checks
the represented degree before `shrink`, then can return a zero root after
shrinking. Restoring that order recovers the Whitney umbrella's singular
center pixel without changing the root algorithm or enabling square-free
conversion. The original quality route also honors
`ClipToSphere.pointClippingNecessary() == false`, so it does not apply the
historical control's additional post-root sphere-point rejection.

`surfer_lighting_test.c` reads actual original collected products, ambient
colors and 288 shade observations. It compares all output RGB and mutated
normal bits. `surfer_original_frame_test.c` reads the actual original prepared
four polynomials and compares all 5412 decoded ARGB pixels in the documented
44 full-canvas frames. These exercise the combined camera, nested
specialization, root, gradient, material, lighting and AA path. Candidate ARGB
records, source/toolchain hashes, exact comparisons and zero-difference
receipts are retained. No tolerance is silently introduced.

The maintained Grease verifier compiles six real mutations: round the specular
dot before its power, use back ambient intensity, normalize in binary64,
choose the front material on a zero dot, route images through historical
shading, and test the trimmed root degree before the original shrink step.
Each must be rejected by a designated raw-bit or image comparison. The
32179-byte historical success control must retain SHA256
`65f44c201676e330068804e4059a369cb6479efa1673660fd78a42681a1f55ca`.

Local qualified ICK execution matches the explicitly labelled Java21/source17
development observations. Hosted JDK17, ASan/UBSan with actual leak detection,
Android target arithmetic and physical devices remain separate gates.
LeakSanitizer cannot run under this local ptraced environment; the maintained
verifier must fail at that boundary rather than publish a local leak PASS.

Actual original production draws use overlapping tiles. Their separate
observations include differences from a single full-canvas task and races
between repeated draws. The full-canvas qualification does not satisfy the
production partition/concurrency obligation. The next numerical slice must
preserve actual tile-local coordinates and AA, compare each actual original
tile, and make ownership/cancellation and any selected original-legal tile
publication order explicit.
