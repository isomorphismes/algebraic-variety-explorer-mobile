# Explorer C67 release-signing intake (source-bound; no publication)

## Current authority boundary

The first consumer is the **checked Idriç Activity** in PR #33, not the
old Java app on the repository's default 'surfer' branch or the NativeActivity
probe in PR #30. The production package is
'org.algebraicvarietyexplorer' (build-values.tsv), versionCode 2 at this
checkpoint, with only 'arm64-v8a' inside the C67 signing input.

The exact-source unsigned producer is
'.github/workflows/native-android.yml' -> 'package-checked-activity' ->
'explorer-c67-unsigned-signing-input-<SOURCE_SHA>'. It retains profile.tsv,
apk.sha256, result.tsv, packaging-head.txt, packaging-status.txt and full
material source evidence. PR #33's 2026-11-22 run 45038600382 passed the
unsigned packaging job and physical-device delivery has not been verified.

The review-only release path is:

1. On the **protected default branch only**, manually dispatch
   '.github/workflows/c67-release-candidate.yml' with the proposed release tag.
   It invokes the reusable exact-source producer in the same workflow run,
   downloads the corresponding C67 unsigned input, and requires that producer
   to pass. PR heads never receive signing credentials through this path.
2. The 'explorer-c67-release-signing' environment must first be configured
   with the existing authorized **persistent** package signing identity,
   required-reviewer protection and these secrets:
   'AVE_RELEASE_KEYSTORE_B64' (base64-encoded PKCS12),
   'AVE_RELEASE_KEYSTORE_PASSWORD', 'AVE_RELEASE_KEY_PASSWORD',
   'AVE_RELEASE_KEY_ALIAS'. Missing inputs fail. No signer is generated,
   replaced, promoted from a test lane or inferred from a branch.
3. Sign the exact unsigned APK with SDK 35.0.1 apksigner using env-scoped
   password transfer. The private keystore is temporary and is not retained.
4. Run 'isomorphisms/ai-ci/android-release-delivery@fcc9ea05c952c75605af5cd8cd23d0db6f31142b'
   on the **finished** APK. The existing registry must contain the authorized
   'org.algebraicvarietyexplorer'/'release' public certificate fingerprint.
   The action checks a single signer, package, release lane, version, exact
   ARM64 ABI, SHA-256 and byte length.
5. 'ci/c67-release-record.sh' compares the verified final APK with every
   unsigned input ZIP member; ties the policy receipt to the exact checked
   source revision, C67 profile, packaging evidence, signed SHA-256, byte count,
   package and version; and prepares one ten-column Cat Food index row.
6. Upload **only** the verification and proposed index-row TSVs. This workflow
   never uploads, releases, emails, attaches, distributes or installs an APK.

## What remains gated

- The central registry currently has no production 'release' row for
  'org.algebraicvarietyexplorer'. Its current test fingerprints are not
  release authority. There is no observable authorized release certificate
  or corresponding keystore available to this workflow.
- The newer app and its release workflow are not yet merged into the default
  branch. Do not sign unmerged PR code with the production identity.
- No Explorer GitHub release currently exists, so the proposed asset URL in
  the candidate row is **not** an acquisition entry. Do not add this row to
  'isomorphisms/catfood/android/apk-delivery.tsv' yet.
- Signed APK bytes are intentionally discarded after this review-only job.
  A later publication must be another reviewed, source-bound signing run,
  and its actual signed bytes, digest, signer, version, policy revision,
  producer revision, and published URL must be rechecked. An old candidate
  receipt is not permission to publish changed bytes.
- Obtain explicit owner approval **before** any release creation, asset upload,
  APK attachment, or APK delivery. Do not run a release operation merely
  because a signed verification receipt exists.

After the owner approves publication and the actual signed asset is live,
independently fetch the published bytes, verify them with the same AICI release
policy and the producer receipt, and review the Cat Food index row before
committing it. Cat Food's 'acquire-android-apk' then binds the exact
repository/source/target to the reviewed row, download SHA-256, byte count,
package and ABI; Flexible Pipes' 'catfood_release_check' compares those
acquired bytes to the outgoing attachment before any send.

## Tests and evidence

'ci/test-c67-release-record.sh' exercises source mismatch, wrong URL,
single-ABI profile, duplicate receipt, wrong policy revision, modified
signed payload with updated synthetic receipt, and digest mutation.
Its fixture APKs are deliberately synthetic *unsigned* ZIP files. This
tests only producer/receipt binding, not signing itself. Real signature,
unregistered release, test-signer and ABI hostile fixtures already execute
under ai-ci PR #365. Cat Food PR #165 and Flexible Pipes PR #268 supply their
own acquisition and attachment gates; do not replace or fork those controls.

When an authorized certificate is identified, publish its **public**
SHA-256 fingerprint and proposed registry row for owner review, together
with evidence that it matches the intended installed package signer (or a
clearly approved migration). Never publish the private key or passwords.
