# Charcoal application presentation

The native formula panel/keypad, empty window margins, preset indicator and
launch window use the shared neutral roles. The ray-traced surface image,
material, lighting and scientific background remain unchanged so the numerical
Java/native image comparison still measures the same rendering problem.

The existing flat reference application consumes the same resources at staging
time. Its old light parent and white formula field are replaced by the shared
theme, charcoal input and light text. Its existing diagnostic report changes
only two color literals. No new Java/Kotlin, Gradle or UI implementation is added.
Package IDs, versions, layouts, input behavior and source ownership are intact.

Canonical C/XML copies come from android-NDK
3e682fb1175beef5625dbd2418730220e49fc9bd. Resource compilation, native ICK builds,
legacy reference tests and actual Android execution remain required. Two inherited
unqualified host `cc` calls now use the existing shared owned ICK host profile,
while all sanitizer assertions remain enabled. Existing Python image verifiers
are retained migration debt; none are introduced or expanded here.

## Signing continuity blocker

The inherited native builder creates a local development key when missing.
Fresh CI runners therefore do not produce an upgrade-compatible certificate.
No persistent nativeprobe key, expected certificate or registered signing
identity was found in the inspected source. These packages remain disposable
emulator fixtures, not approved C67 upgrades. Do not silently substitute another
application's key or uninstall an existing nativeprobe copy to hide a mismatch.
An actual prior signer/private-key recovery or separately authorized migration
is required before physical-device delivery. The legacy reference build also
retains its existing local signer behavior; this visual job claims no new
signing or release authority.

API29/34 both-mode chrome, transition/rotation, dialog and physical C67 acceptance
remain NOT_RUN until independently captured. The seven-surface mathematical
suite, arbitrary formula input and numerical image bounds are not weakened.
