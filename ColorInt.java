/*
 * Android adaptation copyright 2026 Algebraic Variety Explorer contributors.
 *
 * Licensed under the Apache License, Version 2.0.
 */

package de.mfo.jsurf.rendering.cpu;

import javax.vecmath.Color3f;

final class ColorInt
{
    private ColorInt()
    {
    }

    static int toArgb( Color3f color )
    {
        int red = channelToByte( color.x );
        int green = channelToByte( color.y );
        int blue = channelToByte( color.z );
        return 0xff000000 | red << 16 | green << 8 | blue;
    }

    private static int channelToByte( float channel )
    {
        float clamped = Math.max( 0.0f, Math.min( 1.0f, channel ) );
        return Math.round( clamped * 255.0f );
    }
}
