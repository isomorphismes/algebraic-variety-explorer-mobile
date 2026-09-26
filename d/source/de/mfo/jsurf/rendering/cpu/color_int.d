/*
 * Android adaptation copyright 2026 Algebraic Variety Explorer contributors.
 *
 * Licensed under the Apache License, Version 2.0.
 *
 * Compatibility bridge used only because the current Java adaptation routes
 * the inherited renderer into an Android ARGB buffer.
 */
module de.mfo.jsurf.rendering.cpu.color_int;

import std.algorithm.comparison : min, max;
import std.math : round;
import javax.vecmath : Color3f;

int toArgb(Color3f color) {
    const red = channelToByte(color.x);
    const green = channelToByte(color.y);
    const blue = channelToByte(color.z);
    return cast(int)(0xff00_0000u | (red << 16) | (green << 8) | blue);
}

private uint channelToByte(float channel) {
    const clamped = max(0.0f, min(1.0f, channel));
    return cast(uint) round(clamped * 255.0f);
}
