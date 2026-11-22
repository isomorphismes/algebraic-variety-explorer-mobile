# Original orthographic camera reference

This test adapter records the unchanged Stussak camera implementation under
the original application's settings. It contains no matrix inversion, vector
normalization, ray interpolation or replacement camera algorithm. The
candidate camera remains C and needs a separate comparison.

The maintained runner archives original sources from
cfd543e1886bc6b7eb9e1ede6641569b673aac8d. Exact hashes lock RayCreator,
OrthographicCameraRayCreator, Camera, Ray, Helper and the application's
RendererEngine settings. Only the archive's de.mfo.jsurf packages and the
separate current adapter enter compilation. The locked ANTLR 3.4 and
vecmath 1.5.2 JAR digests remain mandatory. In particular, the original
vecmath Matrix4d inverse, multiplication and transform methods execute;
the adapter does not reimplement them.

The runner requires javac 17 with --release 17, records complete source and
dependency hashes, executes the reference twice and compares output bytes.
Its successful result concerns the reference alone.

## Inputs and observations

The adapter applies the same settings as RendererEngine:

- Orthographic camera; base height 2.15, then height 2.15 divided by zoom.
- Camera transform identity with m23 = -1.
- A yaw rotY matrix multiplied by a pitch rotX matrix, in that order.
- Identity surface transform.

It then invokes the actual RayCreator.createRayCreator factory. Package access
reads all three derived Matrix4d fields and the twelve OrthographicCamera
origin/direction/du/dv fields. It records scales, offsets, viewport intervals
and the original eye-location result.

Seven profiles distinguish positive and negative zero angles, square/wide/tall
viewports, positive/negative rotations and zooms 0.55, 1, 1.75 and 6. The
nontrivial profiles include yaw 0.43 and pitch -0.71.

For each profile, nine normalized grid inputs, two inputs beyond the
normalized viewport and four nonbinary fractional pairs pass through actual
transformU and transformV. The added pairs are (0.1,0.3), (0.23,0.77),
(-0.17,1.13) and (0.371,0.619). Each of the four rotated profiles also has
one cancellation-sensitive input: the original transformU evaluates fraction
0.25, and observed clipping basis fields and viewport offsets/scales select
a fractionV that makes the two x-direction contributions nearly cancel.
This calculation chooses an input; every expected coordinate and ray still
comes from the actual original methods. This input targets reassociation of
the original left-to-right interpolation; candidate mutation rejection is a
separate required observation.

All three actual ray constructors execute at the resulting coordinates.
Six parameters, including both signed zeros, pass through each ray's actual
at method. Four normal inputs pass through actual
surfaceSpaceNormalToCameraSpaceNormal.
The adapter supplies normalized test inputs; it does not reproduce the
RenderingTask sampling loop or qualify its start/increment operation order.

There are 672 matrix elements, 84 field vectors, 109 coordinate samples, 327 rays,
1962 ray points and 28 normal transformations. Full images, clipping, shading,
AA, polynomial substitution and target execution remain outside this gate.

## TSV schema

Every record is plain ASCII with tab separators. Binary64 values use sixteen
lowercase hexadecimal digits from Double.doubleToRawLongBits. Indices start
at zero. Matrices use row/column indices, not a host-specific memory layout.

| Record | Fields after the record name |
| --- | --- |
| camera_case | ID WIDTH HEIGHT BASE_HEIGHTbits YAWbits PITCHbits ZOOMbits |
| matrix | ID NAME ROW COLUMN VALUEbits |
| vector | ID NAME Xbits Ybits Zbits |
| scalar | ID NAME VALUEbits |
| interval | ID u-or-v LOWERbits UPPERbits |
| sample | ID INDEX FRACTION_Ubits FRACTION_Vbits ACTUAL_Ubits ACTUAL_Vbits |
| ray | ID INDEX camera-or-clipping-or-surface OXbits OYbits OZbits DXbits DYbits DZbits |
| ray_point | ID INDEX SPACE PARAMETERbits Xbits Ybits Zbits |
| normal | ID INDEX INPUT_Xbits INPUT_Ybits INPUT_Zbits RESULT_Xbits RESULT_Ybits RESULT_Zbits |
| camera_end | ID |

Matrix names are input_view, input_camera, input_surface, camera_to_surface,
camera_to_clipping and surface_normal_to_camera. Vector names start with
camera_, clipping_ or surface_, followed by origin, direction, du or dv.
Scalar names are camera_height, uscale, vscale, uoffset, voffset and eye_location.

## Local exploratory result

The maintained runner parses with the exact retained Grease runtime.
This local image has Java 21's jdk.compiler module but no javac entrypoint or
Java 17 release data. A separately recorded exploratory invocation therefore
used that actual compiler module with -source 17/-target 17 and the local
original-source tree equivalent ea2d392949e53dd4adf46b6aae0c27a956b23b83.
All six locked source hashes were verified. This is not the maintained
frozen-commit/Java 17 gate.

The adapter SHA256 is
82e91b91e42601a95ff0953aafad3d97a51e01402b86ad5e23a1b7e46e3158fa.
Both exploratory executions produced the same 3252-line output, with SHA256
455904b6ab74449752e542e01a34eaabb0dee69539b3dab8679ecfdc31e67105.

The rotated-wide profile illustrates why these raw observations matter:
its actual camera direction's z component is bff0000000000001, its camera
origin has small nonzero x/y offsets, and its clipping origin has small
nonzero components despite the exactly zero surface origin. Its surface_dv
and clipping_dv differ in their final bits. The actual inverse normal matrix
also contains a small nonzero entry where an ideal symbolic rotation would
suggest zero. Candidate code must preserve the observed original operation
sequence instead of substituting an algebraically simplified inverse or
normalized basis. Hosted Java 17 and candidate/target comparisons remain pending.
