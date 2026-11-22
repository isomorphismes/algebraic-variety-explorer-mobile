# Original interruption and publication boundary

The retained original `RenderingTask.java` checks interruption before each
OG_1x1 pixel trace at line 102, each AA corner trace at line 139, and each
advanced-pattern sample, including reused corners, at line 180. It does not
poll within ray tracing, polynomial/root loops, shading or smooth averaging.
`RenderingTask.call()` turns cancellation into `false`; other throwables also
return `false` after printing a stack trace.

`CPUAlgebraicSurfaceRenderer.stopDrawing()` cancels its current FutureTasks
with interruption enabled. This does not join their numerical workers.
`draw()` also combines task results using short-circuit `success && task.get()`,
so a false result can prevent waiting for subsequent tasks. Failed/cancelled
tasks and waiting-thread failures become `RenderingInterruptedException`.
`RendererEngine.render()` then skips row flipping, bitmap creation and result
construction. Cancellation acknowledgement alone never proves that a worker
has stopped accessing its prepared surface or output storage.

`SurfaceRenderController` tests its generation before posting a UI callback,
but the posted callback does not repeat that test. An already queued result
can therefore run after a newer request or close. The new Activity owner must
test closed/currentness when that callback actually executes. This closes an
original delivery race; it is not evidence that the original already supplied
the stronger latest-request guarantee.

The additive C operation polls at samples and inside potentially long
polynomial, Descartes and bisection loops. That deliberately improves cooperative
response without changing completed numerical arithmetic. It keeps retained
surface/session/epoch storage alive until the actual numerical work finishes,
uses a distinct cancellation status, and publishes no partial frame.

This slice owns neither a native thread pool nor the original processor-dependent
overlapping tile partition. Original thread/tile/cancellation scheduling parity
and physical-device acceptance remain separate. The accepted copied immutable
snapshot lifetime rule is retained from `native/prepared-surface-handoff.md`.
