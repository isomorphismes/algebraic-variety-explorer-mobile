# SURFER in D — direct source translation

This directory is a source-to-source D translation of the original Java
`de.mfo.jsurf` code carried in this repository.

The rule for this branch is deliberately different from the older
`d/desktop-surfer` experiment:

- translate from the original Java source, not from the later C renderer;
- preserve the original class and algorithm boundaries unless D makes a
  construct impossible;
- keep one D module traceable to one original Java source file;
- preserve numerical behavior before attempting cleanup or redesign;
- record every intentional language-level deviation in `SOURCE_MAP.md`;
- do not silently substitute the existing compact D recast for untranslated
  Java source.

The first compiling slice is the univariate-polynomial and closed-form-root
solver path:

`UnivariatePolynomial.java` → `univariate_polynomial.d`

`RealRootFinder.java` → `real_root_finder.d`

`ClosedFormRootFinder.java` → `closed_form_root_finder.d`

Build/test this slice with:

```sh
dub test
```

This is only the beginning of the wholesale port. Source presence or compilation
of this slice is not evidence that the full SURFER renderer has been translated
or accepted.
