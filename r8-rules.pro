# Keep every project class and member exactly as written.
# R8 is used only to discard unreachable classes from the two dependency jars.
-keep class org.algebraicvarietyexplorer.** { *; }
-keep class de.mfo.jsurf.** { *; }

-dontobfuscate
-dontoptimize
-dontwarn
