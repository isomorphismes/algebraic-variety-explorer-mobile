# Actual host JVM worker observation

The C observer creates an actual host JVM through `JNI_CreateJavaVM` with
`-Xcheck:jni` and `-XX:-UsePerfData`. It compiles no Java source or classes.
It calls the maintained JNI adapter and actual C copied-surface/session/core
with actual JVM objects and a real `jintArray`.

The types and ownership boundary are: an invocation-owned `JavaVM*`, the
original caller's `JNIEnv*`, actual positive session/epoch/surface scalar
tokens, and caller-owned output-array local reference. Each maintained worker
startup hook acquires its own daemon attachment and Thread.MIN_PRIORITY;
the numerical kernel receives no JVM object. The observer wraps actual tile
entry and exit, uses only `GetEnv` (never attaches), and requires that worker's
actual `Thread.currentThread().getPriority() == 1` and `isDaemon() == true`.
Every observer local reference must be released on its owning thread.

The native owner publishes the completed frame through actual
`SetIntArrayRegion` after its workers finish and detach. The caller checks
status, copies the actual output array, requires a nonuniform opaque frame,
releases native owners and its array reference, then requires successful
`DestroyJavaVM`. This establishes a host JVM JNI/priority/lifetime boundary;
it does not establish Android/ART task profiles, pixels or physical behavior.

The exact build owner is qualified host ICK. The JVM is an external test-only
runtime, including its existing foreign implementation dependencies. The
maintained helper requires actual JDK 17 version/runtime/header inputs and
records their digests and VM output. A local Java 21 run is explicitly a
development diagnostic and cannot satisfy the JDK 17 qualification. The host
JVM's foreign allocations are outside native-owner leak accounting; no claim
about JVM-wide sanitizer/leak cleanliness is made.

This is a C JNI invocation/ownership observer of the requested C implementation,
not a substitute Java application or Idriç fallback. No Idriç language gap is
inferred. The local implementation baseline is excluded from adoption; only
the subsequent new observer/helper/manifest/documentation commit is delivered.

## Local development observation

The observed runtime file existed at
`/usr/lib/jvm/java-21-openjdk-amd64/lib/server/libjvm.so`. Qualified ICK
compiled the actual C observer and production adapter/owners against the
official OpenJDK 17 GA C headers and that installed Java 21 foreign runtime.
This explicitly labelled diagnostic passed with actual in-process version
`21.0.13+9-1-deb13u2-Debian`.

The actual core started four numerical pthread workers and joined four.
Eighteen actual tile operations produced 36 entry/exit observations of
priority 1 and daemon true. Observer local-reference counts were 72 created
and 72 deleted. The actual array contained a nonuniform opaque frame; native
session/epoch/surface owners reached zero; DestroyJavaVM returned successfully.
JVM stderr was empty and stdout contained no CheckJNI warning/fatal diagnostic.

The libjvm SHA-256 was
`22c91f26f57d578d80306b7f6825fe684faa932dbb9b050ce79c129143fa0da7`.
The observer source hash was
`abbd3b676dbb92e73343b1e0e8ea52b3888e290e5101930cb93011afdf745823`;
its binary hash was
`afeb3c66725d8b89879994869b65390104e9d0d72ddc6b71599d9472d3c01ac2`.
The retained stdout hash was
`f4401fcaa0ede08b8373cb7a309c16e425e01644dcc7b762eec89c6260600965`;
stderr had the empty-file hash. Source/runtime digests, compiler output, actual
runtime properties and release metadata were retained in the diagnostic.

The maintained helper parses and correctly refuses this Java 21 installation
at its JDK 17 release-version gate. No maintained JDK 17 passing receipt was
produced locally. Actual JDK 17 CheckJNI and Android/ART remain separate
acceptance steps; no Java 21 result is promoted to either.

The actual-JVM priority negative control also compiled and ran against that
Java 21 runtime. Its sole production-source change was the worker startup
priority literal `1` to `5`. The unmodified observer reported the actual
priority-5 daemon Thread property and the process exited at designated status
1. No CheckJNI warning/fatal diagnostic occurred: rejection came from the
observed Thread property, followed by the expected failed native render.
The negative process intentionally exits on failure and is not VM-destruction
or native-cleanup success evidence. The strict JDK 17 helper now requires this
same independently compiled negative control after its positive run.
