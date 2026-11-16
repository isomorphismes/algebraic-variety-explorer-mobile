# Host Runtime-query observation

The observer includes the actual `render_session_jni.c` and links the actual
session, bounded-worker, copied-surface and numerical core implementations.
Its only replacement is a test-owned external JNI function table defined by
the official JDK 17 headers. Class/method names and descriptors, receiver
identities, positive scalar transfer and caller-thread use are observed.
Opaque tokens are never dereferenced as JVM objects.

Direct queries exercise counts 1, 2, 4, 8 and `INT32_MAX`, reject zero and
negative counts without modifying the scalar output, reject a missing output,
and preserve an already pending exception. Each of the five actual lookup/
invocation stages has a controlled fault. Reference/method stages exercise a
null result, null plus exception, and a value plus exception; integer return
faults exercise a value plus exception and nonpositive values. Every acquired
class/object local reference must be released exactly once. The adapter must
neither clear nor replace the original pending exception.

The same faults pass through the real session-creation and render JNI entry
points. Rejected creation must allocate no native owner. Rejected rendering
must acquire no staging, native worker or surface borrow and must preserve
the caller's sentinel output. Existing fixture owners are released afterward,
with both owner registries and all allocation counters required to reach zero.

Successful JNI creation/render pairs use counts 1→8, 8→1 and 4→2. Creation
fixes the bounded pool limit; each draw performs its own fresh query for the
original tile partition. A separate actual C owner call provides the native
tile pixels for the array-adapter comparison, including Android row order.
This compares transport/publication behavior; mathematical fidelity belongs
to the independent original-renderer corpus.

Link-time observers wrap actual `pthread_create` and `pthread_join`, preserving
their results. Every started numerical worker must have joined before the real
publisher reaches the mock `SetIntArrayRegion`; all observed JNI calls must
occur on the original caller thread. No JNI object or environment is made
available to the numerical implementation.

Three compiled mutations replace the returned scalar with a constant, ignore
the final invocation exception, and omit the Runtime object local-reference
release. Each must compile and fail with the designated observer diagnostic.
The maintained helper also requires ASan/UBSan with leak detection enabled.

Invoke the helper with absolute repository, qualified ICK source/compiler,
JNI header directories and a fresh output directory. On hosted JDK 17 the
header arguments are its actual `JAVA_HOME/include` and `include/linux`.
For the local diagnostic the official OpenJDK tag `jdk-17+35` files came from
`src/java.base/share/native/include/jni.h` and
`src/java.base/unix/native/include/jni_md.h`. They are external platform inputs,
recorded by digest rather than copied into this repository.

This host table/owner test is not actual JVM, Android JNI ABI, ART, installed
APK or physical-device evidence. The official host header does not establish
the Android NDK header or target ABI.
