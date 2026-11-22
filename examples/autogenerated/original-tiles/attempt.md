# Original private tile kernel

The numerical owner is the existing C core receiving four immutable prepared
polynomials from Idriç. A tile is an inclusive rectangle in a complete canvas,
not a separate camera viewport. Its input type is the prepared scene, canvas
dimensions, inclusive pixel bounds, F64 camera state, original sampling quality
and an optional borrowed cancellation predicate. Its output is either a status
or a tightly packed rectangle of ARGB pixels.

`surfer_render_orthographic_tile` performs one actual original task's numerical
sequence. The start coordinate includes the tile's global pixel origin before
the original start-plus-local-index-times-increment loop. OG samples centers;
Final starts half a pixel before the rectangle and owns its expanded corner
grid. The existing original shader, nested polynomial specialization, root
algorithm and camera remain shared with the full-canvas operation. Bounds are
inclusive, including the original overlapping right/top task edges.

The operation owns its transformed XYZ polynomials, two-row cache, dense
univariates and AA corner storage. It retains no pointers after return.
Independent worker calls therefore share only immutable scene storage and a
thread-safe borrowed cancellation predicate. Input refusal happens before pixel
writes; a runtime failure invalidates that private tile. The complete-frame
owner must discard failed/cancelled work and control overlap publication.

The Idriç-side type sketch is a scoped `PreparedSurface` borrow, a bounded
`Canvas`, an inclusive `Rectangle canvas`, and a uniquely owned
`Pixels rectangle`. A synchronous foreign call returns `Either RenderFailure
Pixels`; the rectangle's global coordinate system must not be lost by reducing
it to just width and height. No general helper language replaces Idriç here:
this extends the already selected C numerical boundary.

The independent observer invokes unchanged original `RenderingTask` for every
tile using the original canvas dimensions, records only that rectangle's
pixels, and composes in original submission order. It separately confirms that
the unchanged original production draw under a serial executor produces the
same composition. This demonstrates one original-legal deterministic schedule;
it does not claim that uncontrolled racing production draws have one hash.

The maintained verifier compares every private tile and every composed pixel,
requires the original full-canvas control to remain unchanged, sweeps every
observed private allocation fault and selected cancellation stops, and rejects
compiled mutations of center start, AA start and inclusive width. ASan/UBSan
and actual leak detection are required separately. Max-four-worker scheduling,
session integration, JNI, Android and physical-device acceptance belong to the
complete-frame owner and are not provided by this synchronous kernel.

## Local development evidence

At the qualified ICK revision `fbe86e23d55cfec2000c08e61deea2a407fd7175`,
1812 private original tiles match all 12852 recorded pixels. Their ordered
composition matches all 5412 pixels of the 44-frame corpus, including the nine
frames that differ from a single full-canvas task. The full-canvas control and
the historical 32179-byte successful output remain unchanged. Three compiled
start/bounds mutations are rejected. Both quality modes pass every observed
tile allocation failure (208 OG and 289 Final points) and 17 cancellation stops
each. The ordinary and ASan/UBSan binaries pass against the explicitly labelled
Java21/source17 development reference when local leak detection is disabled.

The maintained verifier correctly stops at LeakSanitizer's refusal of this
ptraced local environment. It does not publish a local leak PASS. Hosted JDK17
and leak acceptance, additional explicit processor-count partitions and the
separate worker owner remain required. Decoded candidate tile and composed
ARGB records are retained alongside source, toolchain and observation hashes;
the equality threshold is exactly zero channel difference.
