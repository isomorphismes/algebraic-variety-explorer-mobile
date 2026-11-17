# Android 6 component-name refusal

At application source head `e737407c243d5d2ddd8a6c33e017d5e906cdf4cc`, the
unsigned APK had SHA-256
`24dd9bc16f7bb74ca2f24abf23306f8b02ac7c90fd0ba850366ff227163aa58d`.
The installed Android 14 and 15 jobs passed all nine screen/PNG scenarios.
The [Android 6 job](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43846106934/job/133238940789)
refused installation with `INSTALL_PARSE_FAILED_MANIFEST_MALFORMED`; no
application behavior ran there.

The packaged XML tree names the Activity `Idric.Generated`. In the
[Android 6.0.1 PackageParser source](https://android.googlesource.com/platform/frameworks/base/+/android-6.0.1_r81/core/java/android/content/pm/PackageParser.java),
`buildClassName` accepts a fully qualified component name only when its first
character is a lowercase ASCII letter. A leading dot is expanded against the
application package; a name without a dot is also package-relative.
`Idric.Generated` has a dot and starts with an uppercase letter, so this
specific source path refuses it. `parseActivity` propagates the refusal as a
malformed manifest.

Changing the XML alone would select a class absent from the actual DEX. The
compiler must legitimately emit the selected Activity owner and all of its
internal references; the manifest, JNI names and observer must agree with that
owner. Rewriting candidate Smali or DEX bytes is not a source-level repair.
The compiler's existing default owner is independently useful to its other
consumers and need not be changed globally.

The application emitter selects
`generated-owner=Lorg/algebraicvarietyexplorer/AVEActivity;`. The compiler
relocates the checked class plans before encoding, including captured Runnable
references. The application source's existing internal checked declarations
retain their default spelling; the selected descriptor is a compiler output
choice. Production JNI builds select the corresponding owner explicitly;
semantic and host JNI fixtures retain their existing default owner. The
manifest and independent observer select the same application class. Fresh
source, packaging and installed checks are required for these changed bytes.

Legacy adbd returned zero for this failed installation. Previously, the
qualifier's bare `Success` assertion then exited before its diagnostic
snapshot. The qualifier now records the separate literal-success check and
captures logcat, processes, activities and package state when either the
command status or that check refuses. The observer install uses the same
rule. Grease parsing passes locally; the next installed run must exercise the
maintained qualifier. No new Android 6 installation PASS is implied by this
source diagnosis.

## Local repair verification

The complete 20-module Activity emitted through the actual owner-selecting
driver with SHA-256
`15fffdb76192d29b949519dadb3dbd21fb7081d28a3efe4e89b13902cd7456d7`
and the retained frontend with SHA-256
`7aebab74161e120a7ffb18ab500468a505a9ae1c32fb5aa3557959c2b584cc97`.
The candidate DEX is 538544 bytes, SHA-256
`c9e678dae0a2cf4c40267e0a7904324a21ff05273e084ec057eb036ca79a96e4`.

The maintained emitter verified the selected directive in checked ANF, the
actual Activity class/superclass, private state, framework interfaces,
lifecycle methods, native declarations and the relocated captured Runnable.
No old generated-owner descriptor remains in the decoded application.
Independent decode and reassembly passed. Reassembly is diagnostic only; the
candidate remains the original compiler output. Production JNI object
qualification also passed the exact ten selected exports, preserved the ten
default fixture exports and rejected an invalid selector value.

These are source, DEX-structure and host-object results. Fresh Android linking,
packaging and installed API 23/34/35 results remain required for the changed
application.
