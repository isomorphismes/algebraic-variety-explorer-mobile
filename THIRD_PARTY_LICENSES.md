# Third-party components

## jsurf

Copyright 2008 Christian Stussak. Apache License 2.0. The adapted source is
included as the root-level Java files in the `de.mfo.jsurf` packages.

## ANTLR runtime 3.4

Copyright the ANTLR project contributors. BSD 3-Clause License.

Source: https://www.antlr3.org/

## Java Vecmath 1.5.2

Copyright the Java Vecmath contributors. GPL version 2 with the Classpath
Exception.

Source: https://github.com/hharrison/vecmath

The C translation of the vecmath 1.5.2 matrix operations is a separate arithmetic
module in `native/surfer_vecmath.c` and `native/surfer_vecmath.h`. Its original
Sun notices and GPLv2 with Classpath Exception are retained; the complete license
is in `native/licenses/vecmath-GPL-2-CE.txt`. The Apache-2.0 camera composition
uses this module through its C declarations.

Source archive: https://repo.maven.apache.org/maven2/javax/vecmath/vecmath/1.5.2/vecmath-1.5.2-sources.jar

Archive SHA256: `7bea4e97b737757c14bc346a45bb5e57a3f6ddd5c1bafe51e4d1eacd64347030`.
License source: https://github.com/hharrison/vecmath/blob/master/LICENSE.txt
License SHA256: `e7cee869f40db280237b128222f6af34e9bd128635afcef306b5b8cca9383a1c`.

The complete dependency sources and license texts are available from the
linked upstream projects and their Maven Central source archives.

The exact artifacts used by the build are recorded in `dependencies.lock`.
