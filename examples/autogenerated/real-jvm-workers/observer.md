# Actual JVM CheckJNI worker observation

The C entry point invokes the actual `JNI_CreateJavaVM`, then calls maintained
production JNI exports directly with actual JVM objects. It compiles no Java
source, generates no class, supplies no replacement Thread class, and does not
enable the JNI mock/fault interface. Test-only native owner counters remain
available so ownership can be checked after release.

The VM options are `-Xcheck:jni`, `-XX:-UsePerfData`, `-Xms16m`, `-Xmx128m`
and `-XX:ActiveProcessorCount=4`. The four-worker bound therefore comes from
the real Runtime query made by the maintained adapter. Link-time observers
count actual C owner `pthread_create` and `pthread_join` operations; both must
be four. They do not intercept foreign JVM-internal thread creation.

At every actual numerical tile entry and exit, an observer uses GetEnv on the
actual JavaVM and requires an already attached worker-owned environment. It
does not attach a thread or change priority. Bootstrap Thread.currentThread(),
getPriority() and isDaemon() must report priority 1 and daemon true. Every
potentially throwing call is followed by ExceptionCheck before another JNI
operation, including the integer/boolean invocations. Observer class/object
locals are deleted on that worker and counted separately. These observations
prove the Java Thread properties through the numerical operation; they do not
prove Android scheduling/task-profile behavior.

The caller owns a real initialized `jintArray`. The actual JNI adapter renders
and publishes a nonuniform opaque sphere frame into it. The caller requires
successful status, reads the array, releases session/epoch/surface ownership
and its array reference, and checks all native-owner counters are zero.
DestroyJavaVM must succeed within the helper's bounded process timeout.

`verify.grease` takes eight absolute paths: repository, qualified ICK source,
qualified ICK compiler, actual JDK root, JNI include directory, JNI platform
include directory, libjvm and a fresh output directory. It requires JDK 17's
release record, executable version and actual in-process runtime property.
Provided headers and library must match that same JDK's actual files. Digests
bind source, compiler and foreign runtime inputs. Compiler output, JVM output,
stderr, release metadata and observation hashes are retained. JVM stderr must
be empty and CheckJNI warning/fatal diagnostics are rejected in stdout too.

A separate compiled negative control changes only the maintained startup
call's priority literal from 1 to 5 in a copied JNI source. It uses the same
actual JVM, observer and CheckJNI options. The process must exit with status 1
and the observer must report the actual `worker priority 5 daemon 1` property.
It must not fail through a JVM warning, invalid JNI call or VM startup error.
Its compiler output, stdout, stderr, source and binary digests are retained.
The positive run still requires empty stderr and successful VM destruction;
the intentionally failing process makes no successful cleanup/shutdown claim.

This real JVM gate complements the separately controlled JNI-table fault
observer. It makes no JVM-wide allocation/sanitizer claim, and it does not
replace Android NDK ABI compilation, ART CheckJNI or installed-device testing.
