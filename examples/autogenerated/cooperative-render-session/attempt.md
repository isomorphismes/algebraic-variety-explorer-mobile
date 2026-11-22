# Cooperative numerical render sessions

## Owner and type sketch before implementation

The numerical C owner admits a positive opaque signed-64 session token and a
fresh positive signed-64 epoch token. These are registry identities, never
addresses, and the source Activity owner performs no arithmetic on them.
Creating a session establishes its lifetime; beginning an epoch invalidates
the previous epoch before work is queued. Cancel invalidates the current
epoch. Release closes the session, invalidates its epoch and defers destruction
until every active numerical call finishes. A currentness query returns true
only for the exact live session/epoch pair. UI completion must repeat that
query when the UI callback executes, not only before queueing that callback.

Session and epoch identity/refcounts are protected by a native mutex. Workers
retain their session and epoch and poll one per-epoch C17 atomic boolean;
64-bit atomics and lock-free assumptions are not required. Epoch cancellation
is irreversible, so an old queued request cannot become current again.

An additive synchronous render operation admits session, epoch and copied
surface tokens plus the existing explicit quality/view/output contract. It
retains the copied surface and the session/epoch for the complete numerical
call, renders into private staging storage, and publishes the whole frame only
after a final currentness check under the registry lock. Cancellation has an
explicit added status and leaves the caller's output unchanged. Failures and
cancellation free every local allocation and balance both lifetimes.
The actual publisher runs inside that critical section, while session/epoch
retains remain live. It borrows the unique mutable finished pixel buffer and
may reverse rows before JNI's single array-region copy; it cannot retain the
buffer or reenter session APIs. The surface borrow ends after tracing and
before publication, so release errors precede any output modification.

The numerical operation context gains an optional synchronous cancellation
predicate. Pixel/sample, polynomial expansion, Descartes and bisection loops
cooperatively poll it without changing successful floating-point arithmetic
or evaluation order. Existing synchronous and quality entry points supply no
predicate and retain their old successful output bytes and status meanings.

The proposed additive JNI shape is
`renderSessionSurface(JJJIIIDDDD[I)I`, ordered session, epoch, surface, width,
height, quality, camera, yaw, pitch, zoom, output. Session creation/begin and
cancel/release/currentness fit the existing checked typed scalar boundary.
The Activity and JNI owners must agree exact symbols before source wiring.
No semantic formula/editor state, global app map, native thread pool, original
tile scheduling or physical-device parity is introduced by this slice.

Deterministic tests must establish stale-before-start refusal, cancellation
inside numerical loops, release/replace during active ownership, unchanged
output on cancellation/failure, balanced allocations and targeted mutant
rejection. Qualified ICK host execution is distinct from ARM32 compilation and
ELF-import evidence. Local ASan/UBSan may run with leak detection disabled
because ptrace blocks LSan; the hosted leak gate remains required.

## Implementation and local observations

The additive context/predicate/status and session registry are implemented.
Existing status values 0–3 retain their meanings; `SURFER_CANCELLED` is 4.
Session and epoch tokens share one mutex-protected monotonic identity source;
epochs cannot be transferred between sessions. Unknown positive, closed and
obsolete pairs query as false. Failed epoch allocation preserves the previous
current epoch. Retired sessions/epochs remain allocated until their final
actual numerical caller returns.

Qualified ICK at `fbe86e23d55cfec2000c08e61deea2a407fd7175`, strict C17,
`-fno-link-libatomic -fno-fast-math -ffp-contract=off`, passes the numerical
checkpoint tests and pthread session tests. The latter cover stale queued work,
cancel/advance/release after both retains and completed tracing, surface release
during a live borrow, two active calls sharing one epoch, allocation failures,
publisher failure and 256 concurrent epoch begins/currentness queries.
Selected cancellation checks stop inside the actual numerical functions; the
normal test frames traverse 2543 and 5084 predicates for OG_1X1 and QUINCUNX.
All session/surface allocation and borrow counters balance after joins.

The actual maintained Grease implementation executed the provenance, ordinary
numerical, registry and host undefined-symbol checks successfully. It then
stopped at its mandatory leak-enabled stage with the observed LSan ptrace
refusal; no local full-script success is claimed. Separate ASan/UBSan runs with
`detect_leaks=0` pass the final core and registry tests. Hosted verification
keeps `detect_leaks=1` mandatory. Host undefined symbols contain no atomic
runtime helpers; ARM32 build/import and JNI/ART observations remain pending.

Four compiled incorrect candidates are rejected at their designated diagnostics:
an ignored predicate, removed bisection polls, a missing retained-epoch flag read,
and a bypassed final currentness gate. The last two distinguish actual numerical
cancellation from late discard and actual transactional publication from a
pre-publication check. Existing numerical/status tests and the original-Java
15-blend/682-pixel AA comparison still pass. Every existing seven-preset legacy
pixel/root observation remains 32179 bytes with SHA256
`65f44c201676e330068804e4059a369cb6479efa1673660fd78a42681a1f55ca`.

The existing qualified native ICK workflow now requires the session helper and
retains its evidence separately. Source Activity coalescing, exception/finally
cleanup, the new JNI wrapper, original thread/tile scheduling and physical
acceptance are owned by their separate integration work; this C slice does not
claim them complete.
