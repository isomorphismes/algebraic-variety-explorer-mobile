# Original specialization reference

This is a test adapter for unchanged Christian Stussak jsurf, not a candidate
renderer or a second implementation of its algorithms. The candidate remains C
after checked Idriç has supplied the four prepared polynomials.

The maintained runner archives original root Java sources from
cfd543e1886bc6b7eb9e1ede6641569b673aac8d. It compiles only that archive's
de.mfo.jsurf packages and the separate test adapter. Seven exact source hashes
lock XYZPolynomial, XYPolynomial, UnivariatePolynomial, Expand, Differentiator
and both transformed row substitutors. ANTLR 3.4 and vecmath 1.5.2 keep the
repository's existing locked digests. The runner requires javac 17 and
--release17, records complete source/adapter/dependency hashes, runs the
reference twice and compares its bytes.

The adapter calls the original renderer's getSurfaceExpression and three
getGradient*Expression methods, then the actual Expand, XYZPolynomial.substitute,
XYZPolynomial.evaluateZ, XYPolynomial.evaluateY and
UnivariatePolynomial.evaluateAt methods. It supplies inputs and records results;
it contains no collect, Kahan, multiplication, substitution or Horner algorithm.
Reflection reads only XYPolynomial's private coefficient/exponent arrays. The
original public/package API supplies the remaining observations.

## Coverage and boundary

Ten formulas comprise the seven original application presets plus large
coefficient cancellation, constant reciprocal division and a cubic designed to
exercise Kahan collection after substitution. Three explicit coordinate maps
are used: axis-aligned, rotated and mixed. Mixed coefficients include 0.1 and
-0.3. Maps have the same AST construction order as the original orthographic
creator: constant, then v, then u, then t. Their actual expanded terms are
recorded, including original zero-term handling.

Each of thirty formula/map cases records all four input and transformed
polynomials. Seven (u,v) pairs include signed zero, -1,1, fractional values and
both signs outside the unit interval. Each of the resulting 840 columns is
evaluated at seven parameters spanning both original Horner branches and
signed zero, for 5880 scalar observations. No column is compacted by the adapter;
its actual getCoeffs length, including leading zero coefficients, is retained.

The inputs are explicit coordinate polynomials. This does not qualify the
camera creator's normalization/offset rounding, lighting, clipping, root
selection, AA, worker tiling, full images or Android execution. C qualification
must compare these original results independently and reject targeted compiled
mutations; original observations alone do not qualify the candidate.

## TSV schema

All values are plain ASCII, separated by tabs. Every binary64 value is sixteen
lowercase hexadecimal digits from Double.doubleToRawLongBits. Names have no
whitespace. Indices start at zero. POLY 0 is the surface; 1, 2, 3 are its original
x,y,z derivatives. AXIS 0, 1, 2 names each spatial coordinate's map.

| Record | Fields after the record name |
| --- | --- |
| case | ID FAMILY_DEGREE |
| formula | ID ORIGINAL_FORMULA |
| map | ID AXIS CONSTANTbits DIRECTIONbits DUBits DVBits |
| map_terms | ID AXIS COUNT |
| map_term | ID AXIS INDEX COEFFICIENTbits T_EXPONENT U_EXPONENT V_EXPONENT |
| input | ID POLY COUNT |
| term | ID POLY INDEX COEFFICIENTbits X_EXPONENT Y_EXPONENT Z_EXPONENT |
| transformed | ID POLY COUNT |
| transformed_term | ID POLY INDEX COEFFICIENTbits T_EXPONENT U_EXPONENT V_EXPONENT |
| row | ID POLY SAMPLE Vbits COUNT |
| row_term | ID POLY SAMPLE INDEX COEFFICIENTbits T_EXPONENT U_EXPONENT |
| column | ID POLY SAMPLE Ubits COUNT |
| coefficient | ID POLY SAMPLE INDEX COEFFICIENTbits |
| evaluation | ID POLY SAMPLE Tbits RESULTbits |
| case_end | ID |

map values specify spatial_coordinate = constant + direction*t + DU*u + DV*v.
The map_terms records are the actual original Expand output, avoiding an
assumption about whether zero entries disappear before substitution.
transformed is observed before evaluateZ, which may compact that original
polynomial itself. Dense coefficient index is the power of t.

## Local exploratory observation

The maintained Java 17 runner parses with the exact retained Grease runtime.
Local execution used the available Java 21 jdk.compiler module with
-source 17/-target 17 because this image has no javac entrypoint or Java 17
release support. It archived local ea2d392949e53dd4adf46b6aae0c27a956b23b83,
the original-source tree equivalent to the remote baseline, and verified all
seven method-owner source digests. This is explicitly an exploratory
observation, not the maintained frozen-commit/Java 17 gate.

The test adapter SHA256 is
2c08cf5b8ddf0d9cdd246e85b5bb606d246fb484c2e6465e3371a856d746c25a.
The 18405-line, 984130-byte output repeats exactly, with SHA256
0647fa461b9029fedf5f6e280ae89d40ef99ee224660efd649755e8750efb08a.
Its counts are 30 cases, 120 input/transformed polynomials, 840 columns and 5880
evaluations. The only local compiler diagnostic is the expected warning that
-source 17/-target 17 does not select Java 17 system modules. Hosted Java 17,
candidate C comparisons, sanitizers and all target evidence remain separate.
