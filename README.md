# Algebraic Variety Explorer

Type a polynomial in `x`, `y`, and `z` and see its surface on your Android phone. Drag to turn it, pinch to zoom, or save the view as a PNG. The app works offline.

![Algebraic Variety Explorer interaction demo](https://raw.githubusercontent.com/isomorphisms/isomorphisms/37d47af8bc67d10c922f2d5e791d57e347c2e611/media/algebraic-variety-explorer-demo-preview.gif)

The app opens with `x^2+y^2+z^2-0.64`. The points where that expression is zero form a sphere of radius 0.8. Try changing `+z^2` to `-z^2` and tap **Render**. Now the surface widens above and below its waist, a hyperboloid of one sheet. You can also pick a torus or a Whitney umbrella from **Examples** and edit its formula. Use `^` for powers and `*` for multiplication.

This is an independent Android port of [IMAGINARY’s SURFER](https://www.imaginary.org/program/surfer). Christian Stussak wrote [jsurf](https://github.com/IMAGINARY/jsurf), the original ray tracer at the heart of the app, for the Mathematisches Forschungsinstitut Oberwolfach. The Android interface and build were made with ChatGPT 5.6 and have not had an independent code or mathematical review.

## Getting the app

There is no published APK on [GitHub Releases](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/releases) yet.

To build a development APK on a computer, install JDK 17, Android SDK Platform 35 and Build Tools 35.0.1. With Bash, curl, zip and unzip available, set `ANDROID_SDK_ROOT` to the SDK directory and run `./build.sh` from this checkout. The signed APK is written to `.build/`.

[Build instructions, source guide, example surfaces and credits](docs/README.md)
