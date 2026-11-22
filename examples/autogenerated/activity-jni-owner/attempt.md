# Application JNI owner selection

Purpose: compile the same maintained C adapters for the source/ART fixtures and
the installed application's compiler-selected Activity without exporting
duplicate aliases.

The owner choice is finite: the undefined build flag keeps `Idric.Generated`;
the explicit value `SURFER_APPLICATION_ACTIVITY_OWNER=1` selects
`org.algebraicvarietyexplorer.AVEActivity`. Other defined values refuse during
preprocessing. The shared macro selects only the JNI function identifier;
parameter types, ownership, numerical work and exception behavior are the
same C source in both modes.

`verify.grease` invokes the pinned owned ICK host compiler on the actual three
JNI implementation files in both modes. It observes exactly ten defined JNI
symbols per mode and refuses an invalid flag. It creates no stand-in native
implementation. These host object checks do not establish Android linking or
ART execution. The production cross-build helper selects the application flag
explicitly and records it with the Activity descriptor in each ABI receipt.

The source/ART qualification helpers compile without that production flag,
retain their original owner, and hash the new shared owner header. Mutant
source copies carry the same header so they test the intended fault rather
than failing from a missing include.

The first local harness draft used an invalid quoted-glob word and passed a
list as a shell word. Grease refused it. The maintained harness uses explicit
object paths and constructs its flag list inside the procedure; no fallback
interpreter was used.
